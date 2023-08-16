package handlers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"cossacklabs/acra-translator-demo/internal/models"
	"cossacklabs/acra-translator-demo/internal/persistence"
	acra_translator "cossacklabs/acra-translator-demo/internal/pkg/acra-translator"
	"cossacklabs/acra-translator-demo/internal/services"
	"cossacklabs/acra-translator-demo/pkg/errors"
	"cossacklabs/acra-translator-demo/pkg/render"

	"go.uber.org/zap"
)

type User struct {
	db               persistence.DB
	translatorClient acra_translator.Client
}

func NewUser(db persistence.DB, client acra_translator.Client) User {
	return User{
		db,
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
	var userBody models.User
	err := u.parseFromRequest(r, &userBody)
	if err != nil {
		zap.S().Info("unable to parse request body", zap.Error(err))
		render.Error(w, r, errors.NewInvalidInputError(fmt.Sprintf("unable to parse api user model - %s", err.Error())))
		return
	}

	if err := userBody.Validate(); err != nil {
		zap.S().Info("failed on User validation", zap.Error(err))
		render.Error(w, r, errors.NewInvalidInputError(fmt.Sprintf("invalid input provided - %s", err.Error())))
		return
	}

	userCtrl := services.NewUserController(u.db, u.translatorClient)
	user, err := userCtrl.Save(r.Context(), userBody)
	if err != nil {
		zap.S().Info("failed to save user to DB", zap.Error(err))
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

	userCtrl := services.NewUserController(u.db, u.translatorClient)
	user, err := userCtrl.GetByID(r.Context(), userID)
	if err != nil {
		zap.S().Info("failed to save user to DB", zap.Error(err))
		render.Error(w, r, err)
		return
	}

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

	userCtrl := services.NewUserController(u.db, u.translatorClient)
	user, err := userCtrl.GetByEmail(r.Context(), email)
	if err != nil {
		zap.S().Info("failed to get user by email", zap.Error(err))
		render.Error(w, r, err)
		return
	}

	render.Success(w, user)
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

	userCtrl := services.NewUserController(u.db, u.translatorClient)
	if err = userCtrl.StoreUserDoc(r.Context(), file, userID); err != nil {
		zap.S().Info("failed to save user docs", zap.Error(err))
		render.Error(w, r, err)
		return
	}

	render.Success(w, nil)
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

	userCtrl := services.NewUserController(u.db, u.translatorClient)
	data, err := userCtrl.GetUserDoc(r.Context(), userID)
	if err != nil {
		zap.S().Info("failed to save user docs", zap.Error(err))
		render.Error(w, r, err)
		return
	}

	w.Header().Set("Content-Type", "application/octet-stream")
	w.Write(data)
}

func (u User) parseFromRequest(r *http.Request, target interface{}) error {
	err := json.NewDecoder(r.Body).Decode(target)
	if err != nil {
		return fmt.Errorf("failed to decode request Body - %s", err.Error())
	}

	return nil
}
