package models

import (
	"time"

	validation "github.com/go-ozzo/ozzo-validation"
)

type User struct {
	ID              string    `json:"id"`
	Firstname       string    `json:"firstname" validate:"required"`
	Surname         string    `json:"surname" validate:"required"`
	Zipcode         int32     `json:"zipcode" validate:"required"`
	City            string    `json:"city" validate:"required"`
	ResidentCountry string    `json:"resident_country" validate:"required"`
	Citizenship     string    `json:"citizenship" validate:"required"`
	PhoneNumber     string    `json:"phone_number" validate:"required"`
	Email           string    `json:"email" validate:"required"`
	Notes           string    `json:"notes,omitempty" validate:"required"`
	DocPath         *string   `json:"doc_path,omitempty"`
	Birthday        time.Time `json:"birthday,omitempty" format:"date-time" validate:"required"`
}

func (user User) Validate() error {
	return validation.ValidateStruct(&user,
		validation.Field(&user.Firstname, validation.Required),
		validation.Field(&user.Surname, validation.Required),
		validation.Field(&user.Birthday, validation.Required),
		validation.Field(&user.Zipcode, validation.Required),
		validation.Field(&user.City, validation.Required),
		validation.Field(&user.ResidentCountry, validation.Required),
		validation.Field(&user.Citizenship, validation.Required),
		validation.Field(&user.PhoneNumber, validation.Required),
		validation.Field(&user.Email, validation.Required),
		validation.Field(&user.Notes, validation.Required),
	)
}
