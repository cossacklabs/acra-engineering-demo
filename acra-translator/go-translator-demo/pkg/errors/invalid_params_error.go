package errors

import (
	"net/http"
)

type InvalidParamError struct {
	BaseError
}

func NewInvalidInputError(message string) *InvalidParamError {
	return &InvalidParamError{
		BaseError{
			Code:     "invalid_input",
			Message:  message,
			HTTPCode: http.StatusBadRequest,
		},
	}
}

func NewParseRequestBodyErr(err error) error {
	parseErr := NewInvalidInputError("Error on parsing request body")
	return parseErr.SetDescription(err.Error())
}
