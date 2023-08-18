package handlers

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"cossacklabs/acra-translator-demo/acra-translator"
	"cossacklabs/acra-translator-demo/models"
	"cossacklabs/acra-translator-demo/pkg/errors"
	"cossacklabs/acra-translator-demo/pkg/http/render"
	"cossacklabs/acra-translator-demo/repositories"
)

type User struct {
	userRepo         repositories.User
	translatorClient acra_translator.Client
}

func NewUser(userRepo repositories.User, client acra_translator.Client) User {
	return User{
		userRepo,
		client,
	}
}

// Save
//
//	@Summary
//	@Accept		json
//	@Produce	json
//
//	@Router		/users [POST]
//
//	@Param		user_payload	body		models.User	true	"user payload"
//
//	@Success	200				{object}	render.SuccessResponse{data=models.User}
//	@Failure	400,404,500		{object}	render.ErrorResponse{error=render.Result}
//
//	@tags		User Management
func (u User) Save(w http.ResponseWriter, r *http.Request) {
	var user models.User
	err := u.parseFromRequest(r, &user)
	if err != nil {
		render.Error(w, r, errors.NewInvalidInputError(fmt.Sprintf("unable to parse api user model - %s", err.Error())))
		return
	}

	if err := user.Validate(); err != nil {
		render.Error(w, r, errors.NewInvalidInputError(fmt.Sprintf("invalid input provided - %s", err.Error())))
		return
	}

	// Here is the example if synchronous call to AcraTranslator.
	// It can be simplified via using the BulkAPI supported by AcraTranslator Enterprise version:
	// https://docs.cossacklabs.com/acra/guides/integrating-acra-translator-into-new-infrastructure/http_api/#bulk-processing-api-enterprise
	//
	// Example of interaction via BulkAPI:
	//
	//type RequestData struct {
	//	Data interface{} `json:"data"`
	//}
	//type Request struct {
	//	RequestID   int         `json:"request_id"`
	//	Operation   string      `json:"operation"`
	//	RequestData RequestData `json:"request_data"`
	//}
	//
	//type BulkRequest struct {
	//	Requests []Request
	//}
	//
	//requests := []Request{
	//	{
	//		RequestID: 1,
	//		Operation: "encrypt",
	//		RequestData: RequestData{
	//			Data: user.Firstname,
	//		},
	//	},
	//	{
	//		RequestID: 2,
	//		Operation: "tokenize",
	//		RequestData: RequestData{
	//			Data: user.Zipcode,
	//		},
	//	},
	//}
	//
	//bulkResponse, err := u.translatorClient.CallBulk(ctx, BulkRequest{
	//	Requests: requests,
	//})

	resp, err := u.translatorClient.Encrypt([]byte(user.Firstname))
	if err != nil {
		render.Error(w, r, err)
		return
	}
	user.Firstname = resp.Data

	resp, err = u.translatorClient.Encrypt([]byte(user.Surname))
	if err != nil {
		render.Error(w, r, err)
		return
	}
	user.Surname = resp.Data

	resp, err = u.translatorClient.EncryptSearchable([]byte(user.Email))
	if err != nil {
		render.Error(w, r, err)
		return
	}
	user.Email = resp.Data

	tokenResp, err := u.translatorClient.Tokenize(user.Zipcode, acra_translator.TokenTypeInt32)
	if err != nil {
		render.Error(w, r, err)
		return
	}
	user.Zipcode = int32(tokenResp.Data.(float64))

	if err := u.userRepo.Save(r.Context(), &user); err != nil {
		render.Error(w, r, err)
		return
	}

	render.Success(w, user)
}

// GetByID
//
//	@Summary	Return user by uuid ID
//	@Accept		json
//	@Produce	json
//
//	@Router		/users/{user_id} [GET]
//
//	@Param		user_id		path		string	true	"UserID"	maxlength(66)
//
//	@Success	200			{object}	render.SuccessResponse{data=models.User}
//	@Failure	400,404,500	{object}	render.ErrorResponse{error=render.Result}
//
//	@tags		User Management
func (u User) GetByID(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "user_id")
	if userID == "" {
		render.Error(w, r, errors.NewInvalidInputError("expected user_id provided"))
		return
	}

	_, err := uuid.Parse(userID)
	if err != nil {
		render.Error(w, r, errors.NewInvalidInputError(fmt.Sprintf("invalid userID format - %s", err.Error())))
		return
	}

	user, err := u.userRepo.FindByID(r.Context(), userID)
	if err != nil {
		render.Error(w, r, err)
		return
	}

	resp, err := u.translatorClient.Decrypt([]byte(user.Firstname))
	if err != nil {
		render.Error(w, r, err)
		return
	}
	decoded, _ := base64.StdEncoding.DecodeString(resp.Data)
	user.Firstname = string(decoded)

	resp, err = u.translatorClient.Decrypt([]byte(user.Surname))
	if err != nil {
		render.Error(w, r, err)
		return
	}
	decoded, _ = base64.StdEncoding.DecodeString(resp.Data)
	user.Surname = string(decoded)

	resp, err = u.translatorClient.DecryptSearchable([]byte(user.Email))
	if err != nil {
		render.Error(w, r, err)
		return
	}
	decoded, _ = base64.StdEncoding.DecodeString(resp.Data)
	user.Email = string(decoded)

	tokenResp, err := u.translatorClient.Detokenize(user.Zipcode, acra_translator.TokenTypeInt32)
	if err != nil {
		render.Error(w, r, err)
		return
	}
	user.Zipcode = int32(tokenResp.Data.(float64))

	render.Success(w, user)
}

// GetByID
//
//	@Summary	Return user by email
//	@Accept		json
//	@Produce	json
//
//	@Router		/users/search/{email} [GET]
//
//	@Param		email		path		string	true	"User email"	maxlength(66)
//
//	@Success	200			{object}	render.SuccessResponse{data=models.User}
//	@Failure	400,404,500	{object}	render.ErrorResponse{error=render.Result}
//
//	@tags		User Management
func (u User) GetByEmail(w http.ResponseWriter, r *http.Request) {
	email := chi.URLParam(r, "email")
	if email == "" {
		render.Error(w, r, errors.NewInvalidInputError("expected email provided"))
		return
	}

	email, err := url.QueryUnescape(email)
	if err != nil {
		render.Error(w, r, errors.NewInvalidInputError("invalid email param provided"))
		return
	}

	resp, err := u.translatorClient.GenerateQueryHash([]byte(email))
	if err != nil {
		render.Error(w, r, err)
		return
	}

	result, err := u.userRepo.FindByEmailSubstr(r.Context(), resp.Data)
	if err != nil {
		render.Error(w, r, err)
		return
	}

	users := make([]models.User, 0, len(result))
	for i := range result {
		user := result[i]
		resp, err := u.translatorClient.Decrypt([]byte(user.Firstname))
		if err != nil {
			render.Error(w, r, err)
			return
		}
		decoded, _ := base64.StdEncoding.DecodeString(resp.Data)
		user.Firstname = string(decoded)

		resp, err = u.translatorClient.Decrypt([]byte(user.Surname))
		if err != nil {
			render.Error(w, r, err)
			return
		}
		decoded, _ = base64.StdEncoding.DecodeString(resp.Data)
		user.Surname = string(decoded)

		resp, err = u.translatorClient.DecryptSearchable([]byte(user.Email))
		if err != nil {
			render.Error(w, r, err)
			return
		}
		decoded, _ = base64.StdEncoding.DecodeString(resp.Data)
		user.Email = string(decoded)

		tokenResp, err := u.translatorClient.Detokenize(user.Zipcode, acra_translator.TokenTypeInt32)
		if err != nil {
			render.Error(w, r, err)
			return
		}
		user.Zipcode = int32(tokenResp.Data.(float64))
		users = append(users, user)
	}

	render.Success(w, users)
}

// UploadUserDocs
//
//	@Summary	Upload user docs
//	@Accept		multipart/form-data
//	@Produce	json
//
//	@Router		/users/{user_id}/docs [put]
//
//	@Param		user_id		path		string	true	"User ID"	maxlength(66)
//
//	@Param		file		formData	file	true	"User Doc"
//
//	@Success	200			{object}	render.SuccessResponse{data=models.User}
//	@Failure	400,404,500	{object}	render.ErrorResponse{error=render.Result}
//
//	@tags		User Management
func (u User) UploadUserDocs(w http.ResponseWriter, r *http.Request) {
	r.ParseMultipartForm(0)
	file, _, err := r.FormFile("file")
	if err != nil {
		render.Error(w, r, errors.NewInvalidInputError("get multipart file error"))
		return
	}

	userID := chi.URLParam(r, "user_id")
	if userID == "" {
		render.Error(w, r, errors.NewInvalidInputError("expected user_id provided"))
		return
	}

	_, err = uuid.Parse(userID)
	if err != nil {
		render.Error(w, r, errors.NewInvalidInputError(fmt.Sprintf("invalid userID format - %s", err.Error())))
		return
	}

	user, err := u.userRepo.FindByID(r.Context(), userID)
	if err != nil {
		render.Error(w, r, err)
		return
	}

	fileContent := make([]byte, 0)
	buf := bytes.NewBuffer(fileContent)
	if _, err := io.Copy(buf, file); err != nil {
		render.Error(w, r, err)
		return
	}

	f := struct {
		FileContent []byte
	}{
		FileContent: buf.Bytes(),
	}

	resp, err := u.translatorClient.Encrypt(f.FileContent)
	if err != nil {
		render.Error(w, r, err)
		return
	}

	userFile, err := os.CreateTemp("/tmp", userID)
	if err != nil {
		render.Error(w, r, err)
		return
	}

	_, err = io.Copy(userFile, bytes.NewBuffer([]byte(resp.Data)))
	if err != nil {
		render.Error(w, r, err)
		return
	}
	path := userFile.Name()
	user.DocPath = &path

	if err := u.userRepo.Update(r.Context(), user); err != nil {
		render.Error(w, r, err)
		return
	}

	render.Success(w, user)
}

// GetUserDocs
//
//	@Summary	Get user docs
//	@Produce	multipart/form-data
//
//	@Router		/users/{user_id}/docs [get]
//
//	@Param		user_id		path		string	true	"User ID"	maxlength(66)
//
//	@Success	200			{file}		file
//	@Failure	400,404,500	{object}	render.ErrorResponse{error=render.Result}
//
//	@tags		User Management
func (u User) GetUserDocs(w http.ResponseWriter, r *http.Request) {
	userID := chi.URLParam(r, "user_id")
	if userID == "" {
		render.Error(w, r, errors.NewInvalidInputError("expected user_id provided"))
		return
	}

	_, err := uuid.Parse(userID)
	if err != nil {
		render.Error(w, r, errors.NewInvalidInputError(fmt.Sprintf("invalid userID format - %s", err.Error())))
		return
	}
	user, err := u.userRepo.FindByID(r.Context(), userID)
	if err != nil {
		render.Error(w, r, err)
		return
	}

	if user.DocPath == nil {
		render.Error(w, r, errors.NewNotFoundError("docs path not found"))
		return
	}

	bytes, err := os.ReadFile(*user.DocPath)
	if err != nil {
		render.Error(w, r, err)
		return
	}

	f := struct {
		FileContent string
	}{
		FileContent: string(bytes),
	}

	resp, err := u.translatorClient.Decrypt([]byte(f.FileContent))
	if err != nil {
		render.Error(w, r, err)
		return
	}
	decoded, _ := base64.StdEncoding.DecodeString(resp.Data)

	w.Header().Set("Content-Type", "application/octet-stream")
	w.Write(decoded)
}

func (u User) parseFromRequest(r *http.Request, target interface{}) error {
	err := json.NewDecoder(r.Body).Decode(target)
	if err != nil {
		return fmt.Errorf("failed to decode request Body - %s", err.Error())
	}

	return nil
}
