package persistence

import (
	"go.mongodb.org/mongo-driver/mongo"

	"cossacklabs/acra-translator-demo/internal/repositories"
)

// DB main persistence interface
type DB interface {
	UserRepository() repositories.User
}

type db struct {
	userRepo repositories.User
}

func NewDB(mongoDB *mongo.Database) DB {
	return &db{
		userRepo: repositories.NewUser(mongoDB),
	}
}

func (m *db) UserRepository() repositories.User {
	return m.userRepo
}
