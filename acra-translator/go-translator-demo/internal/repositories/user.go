package repositories

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"cossacklabs/acra-translator-demo/internal/models"
	errors2 "cossacklabs/acra-translator-demo/pkg/errors"
	"cossacklabs/acra-translator-demo/pkg/serialize"
)

const UserCollection = "users"

var ErrUserNotFound = errors.New("user not found")

type User interface {
	Save(ctx context.Context, users *models.User) error
	FindByID(ctx context.Context, id string) (models.User, error)
	Update(ctx context.Context, user models.User) error
	FindByEmailSubstr(ctx context.Context, email string) ([]models.User, error)
}

type user struct {
	db *mongo.Database
}

func NewUser(db *mongo.Database) User {
	return &user{
		db: db,
	}
}

func (r user) Update(ctx context.Context, user models.User) error {
	filter := bson.D{{"id", user.ID}}
	update := bson.D{{"$set", bson.D{
		{"firstname", user.Firstname},
		{"surname", user.Surname},
		{"zipcode", user.Zipcode},
		{"city", user.City},
		{"resident_country", user.ResidentCountry},
		{"citizenship", user.Citizenship},
		{"phone_number", user.PhoneNumber},
		{"email", user.Email},
		{"notes", user.Notes},
		{"doc_path", user.DocPath},
		{"birthday", user.Birthday},
	}}}

	_, err := r.db.Collection(UserCollection).UpdateOne(ctx, filter, update)
	if err != nil {
		return err
	}

	return nil
}

func (r user) FindByID(ctx context.Context, id string) (models.User, error) {
	dbResult := r.db.Collection(UserCollection).FindOne(ctx, bson.D{bson.E{
		Key:   "id",
		Value: id,
	}})

	if errors.Is(dbResult.Err(), mongo.ErrNoDocuments) {
		return models.User{}, errors2.NewNotFoundError(ErrUserNotFound.Error())
	}

	if dbResult.Err() != nil {
		return models.User{}, dbResult.Err()
	}

	var rawData bson.M
	if err := dbResult.Decode(&rawData); err != nil {
		return models.User{}, err
	}

	var user models.User
	if err := serialize.FromBson(rawData, &user); err != nil {
		return models.User{}, err
	}

	return user, nil
}

func (r user) FindByEmailSubstr(ctx context.Context, email string) ([]models.User, error) {
	pipeline := mongo.Pipeline{
		{
			{"$match", bson.D{{
				Key: "$expr",
				Value: bson.D{{
					Key: "$eq",
					Value: bson.A{bson.D{{
						Key:   "$substr",
						Value: []interface{}{"$email", 0, len(email)},
					}}, email}},
				}},
			}}},
	}

	cursor, err := r.db.Collection(UserCollection).Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	users := make([]models.User, 0)
	for cursor.Next(ctx) {
		var rawData bson.M
		if err := cursor.Decode(&rawData); err != nil {
			return nil, err
		}

		var user models.User
		if err := serialize.FromBson(rawData, &user); err != nil {
			return nil, err
		}

		users = append(users, user)
	}

	return users, nil
}

func (r user) Save(ctx context.Context, user *models.User) error {
	user.ID = uuid.New().String()

	bsonDoc, err := serialize.ToBson(user)
	if err != nil {
		return err
	}

	_, err = r.db.Collection(UserCollection).InsertOne(ctx, bsonDoc)
	return err
}
