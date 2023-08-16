package services

import (
	"bytes"
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"reflect"

	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"

	"cossacklabs/acra-translator-demo/internal/models"
	"cossacklabs/acra-translator-demo/internal/persistence"
	acra_translator "cossacklabs/acra-translator-demo/internal/pkg/acra-translator"
	errors2 "cossacklabs/acra-translator-demo/pkg/errors"
)

var ErrNoUserDocs = errors.New("no user docs uploaded")

type UserController struct {
	db               persistence.DB
	translatorClient acra_translator.Client
}

func NewUserController(db persistence.DB, client acra_translator.Client) UserController {
	return UserController{
		db,
		client,
	}
}

func (ctrl UserController) Save(ctx context.Context, user models.User) (models.User, error) {
	if err := ctrl.callTranslator(&user, ctrl.encrypt, "Firstname", "Surname"); err != nil {
		zap.S().With(err).Errorln("failed to encrypt user")
		return models.User{}, err
	}

	if err := ctrl.callTranslator(&user, ctrl.encryptSearchable, "Email", "PhoneNumber"); err != nil {
		zap.S().With(err).Errorln("failed to encryptSearchable user")
		return models.User{}, err
	}

	err := ctrl.db.UserRepository().Save(ctx, &user)
	return user, err
}

func (ctrl UserController) GetByID(ctx context.Context, userID string) (models.User, error) {
	user, err := ctrl.db.UserRepository().FindByID(ctx, userID)
	if err != nil {
		return models.User{}, err
	}

	if err := ctrl.callTranslator(&user, ctrl.decrypt, "Firstname", "Surname"); err != nil {
		zap.S().With(err).Errorln("failed to decrypt user")
		return models.User{}, err
	}

	if err := ctrl.callTranslator(&user, ctrl.decryptSearchable, "Email", "PhoneNumber"); err != nil {
		zap.S().With(err).Errorln("failed to decrypt user")
		return models.User{}, err
	}

	return user, nil
}

func (ctrl UserController) StoreUserDoc(ctx context.Context, file multipart.File, userID string) error {
	user, err := ctrl.db.UserRepository().FindByID(ctx, userID)
	if err != nil {
		return err
	}

	fileContent := make([]byte, 0)
	buf := bytes.NewBuffer(fileContent)
	if _, err := io.Copy(buf, file); err != nil {
		return err
	}

	f := struct {
		FileContent []byte
	}{
		FileContent: buf.Bytes(),
	}

	if err := ctrl.callTranslator(&f, ctrl.encrypt, "FileContent"); err != nil {
		zap.S().With(err).Errorln("failed to encrypt user docs")
		return err
	}

	userFile, err := os.CreateTemp("/tmp", userID)
	if err != nil {
		return err
	}

	_, err = io.Copy(userFile, bytes.NewBuffer(f.FileContent))
	if err != nil {
		zap.S().With(err).Errorln("failed to store encrypted user docs")
		return err
	}
	path := userFile.Name()
	user.DocPath = &path

	return ctrl.db.UserRepository().Update(ctx, user)
}

func (ctrl UserController) GetUserDoc(ctx context.Context, userID string) ([]byte, error) {
	user, err := ctrl.db.UserRepository().FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	if user.DocPath == nil {
		return nil, errors2.NewNotFoundError(ErrNoUserDocs.Error())
	}

	bytes, err := os.ReadFile(*user.DocPath)
	if err != nil {
		return nil, err
	}

	f := struct {
		FileContent string
	}{
		FileContent: string(bytes),
	}

	if err := ctrl.callTranslator(&f, ctrl.decryptFile, "FileContent"); err != nil {
		zap.S().With(err).Errorln("failed to encrypt user docs")
		return nil, err
	}

	decoded, err := base64.StdEncoding.DecodeString(f.FileContent)
	if err != nil {
		return nil, err
	}

	return decoded, err
}

func (ctrl UserController) GetByEmail(ctx context.Context, email string) ([]models.User, error) {
	resp, err := ctrl.translatorClient.GenerateQueryHash([]byte(email))
	if err != nil {
		return nil, err
	}

	users, err := ctrl.db.UserRepository().FindByEmailSubstr(ctx, resp.Data)
	if err != nil {
		return nil, err
	}

	for i := range users {
		if err := ctrl.callTranslator(&users[i], ctrl.decryptSearchable, "Email", "PhoneNumber"); err != nil {
			zap.S().With(err).Errorln("failed to decrypt searchable user")
			return nil, err
		}

		if err := ctrl.callTranslator(&users[i], ctrl.decrypt, "Firstname", "Surname"); err != nil {
			zap.S().With(err).Errorln("failed to decrypt user")
			return nil, err
		}
	}

	return users, nil
}

func (ctrl UserController) callTranslator(data interface{}, callback func(key string, data []byte, result map[string]string) error, fields ...string) error {
	errGroup := new(errgroup.Group)
	result := make(map[string]string, len(fields))

	for _, f := range fields {
		fieldName := f

		val := []byte{}
		field := reflect.ValueOf(data).Elem().FieldByName(fieldName)
		switch field.Type().String() {
		case "string":
			val = []byte(field.String())
		case "[]uint8":
			val = field.Bytes()
		}
		errGroup.Go(func() error {
			return callback(fieldName, val, result)
		})
	}

	// Wait for all HTTP fetches to complete.
	if err := errGroup.Wait(); err != nil {
		return err
	}

	for _, f := range fields {
		fieldName := f
		resValue, ok := result[fieldName]
		if !ok {
			return fmt.Errorf("not field %s found in result set after encryption", fieldName)
		}
		field := reflect.ValueOf(data).Elem().FieldByName(fieldName)
		switch field.Type().String() {
		case "string":
			field.SetString(resValue)
		case "[]uint8":
			field.SetBytes([]byte(resValue))
		}
	}

	return nil
}

func (ctrl UserController) encrypt(key string, data []byte, result map[string]string) error {
	resp, err := ctrl.translatorClient.Encrypt(data)
	if err != nil {
		return err
	}

	result[key] = resp.Data
	return nil
}

func (ctrl UserController) encryptSearchable(key string, data []byte, result map[string]string) error {
	resp, err := ctrl.translatorClient.EncryptSearchable(data)
	if err != nil {
		return err
	}

	result[key] = resp.Data
	return nil
}

func (ctrl UserController) decrypt(key string, data []byte, result map[string]string) error {
	resp, err := ctrl.translatorClient.Decrypt(data)
	if err != nil {
		return err
	}

	decoded, err := base64.StdEncoding.DecodeString(resp.Data)
	if err != nil {
		return err
	}

	result[key] = string(decoded)
	return nil
}

func (ctrl UserController) decryptFile(key string, data []byte, result map[string]string) error {
	resp, err := ctrl.translatorClient.Decrypt(data)
	if err != nil {
		return err
	}

	result[key] = resp.Data
	return nil
}

func (ctrl UserController) decryptSearchable(key string, data []byte, result map[string]string) error {
	resp, err := ctrl.translatorClient.DecryptSearchable(data)
	if err != nil {
		return err
	}

	decoded, err := base64.StdEncoding.DecodeString(resp.Data)
	if err != nil {
		return err
	}

	result[key] = string(decoded)
	return nil
}
