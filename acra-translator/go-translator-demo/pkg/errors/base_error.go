package errors

type BaseError struct {
	Code        string
	Message     string
	Description string
	HTTPCode    int
}

type Error interface {
	GetCode() string
	GetMessage() string
	GetDescription() string
	GetHTTPCode() int
}

func (e *BaseError) Error() string {
	return e.Message
}

func (e *BaseError) SetDescription(desc string) error {
	e.Description = desc
	return e
}

func (e *BaseError) GetCode() string {
	return e.Code
}

func (e *BaseError) GetMessage() string {
	return e.Message
}

func (e *BaseError) GetDescription() string {
	return e.Description
}

func (e *BaseError) GetHTTPCode() int {
	return e.HTTPCode
}
