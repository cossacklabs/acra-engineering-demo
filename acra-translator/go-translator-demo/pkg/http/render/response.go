package render

import (
	"encoding/json"
	"net/http"

	"go.uber.org/zap"

	"cossacklabs/acra-translator-demo/pkg/errors"
)

type Result struct {
	Code    string      `json:"code,omitempty"`
	Message interface{} `json:"message,omitempty"`
}

type ErrorResponse struct {
	Error Result `json:"error,omitempty"`
}

type SuccessResponse struct {
	Data interface{} `json:"data"`
}

type PaginatedResponse struct {
	SuccessResponse
	ItemCount uint64 `json:"item_count"`
	PageCount uint64 `json:"page_count"`
}

type PaginationResult struct {
	ItemCount uint64      `json:"item_count"`
	PageCount uint64      `json:"page_count"`
	Data      interface{} `json:"data"`
}

func NewPaginatedResponseFromResult(result *PaginationResult) PaginatedResponse {
	return PaginatedResponse{
		SuccessResponse: SuccessResponse{
			Data: result.Data,
		},
		ItemCount: result.ItemCount,
		PageCount: result.PageCount,
	}
}

func Error(w http.ResponseWriter, r *http.Request, err error) {
	var (
		response ErrorResponse
		httpCode int
	)
	switch castedErr := err.(type) {
	case errors.Error:
		httpCode = castedErr.GetHTTPCode()
		response.Error = Result{
			Code:    castedErr.GetCode(),
			Message: castedErr.GetMessage(),
		}
	default:
		httpCode = http.StatusInternalServerError
		response.Error = Result{
			Code: "internal_error",
		}
		zap.S().With(zap.Error(err)).Errorw("unhandled server error", "urlPath", r.URL.Path)
	}

	writeJSON(w, httpCode, response)
}

func Success(w http.ResponseWriter, result interface{}) {
	if result, ok := result.(*PaginationResult); ok {
		writeJSON(w, http.StatusOK, NewPaginatedResponseFromResult(result))
		return
	}

	writeJSON(w, http.StatusOK, SuccessResponse{Data: result})
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	marshaled, err := json.Marshal(data)
	if err != nil {
		http.Error(w, "error while render response", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	w.Write(marshaled)
}
