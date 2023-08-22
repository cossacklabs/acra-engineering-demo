package errors

import (
	"errors"
	"net/http"
)

var ErrDuplicateEntity = errors.New("duplicate entry found error")

type NotFoundError struct {
	BaseError
}

func NewNotFoundError(message string) error {
	return &NotFoundError{
		BaseError{
			Code:     "not_found",
			Message:  message,
			HTTPCode: http.StatusNotFound,
		},
	}
}
