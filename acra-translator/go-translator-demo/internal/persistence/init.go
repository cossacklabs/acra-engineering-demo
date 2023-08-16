package persistence

import (
	"context"
	"log"
	"net/url"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// InitMongoDB initialize connection to MongoDB
func InitMongoDB(ctx context.Context, mongoDBURI *url.URL) (*mongo.Database, error) {
	log.Println("Connecting to MongoDB...")
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(mongoDBURI.String()))
	if err != nil {
		return nil, err
	}

	if err := client.Ping(ctx, nil); err != nil {
		log.Printf("Could not ping mongo: %s", err)
		return nil, err
	}

	log.Println("Successfully connected to MongoDB")
	return client.Database(strings.TrimLeft(mongoDBURI.Path, "/")), nil
}

func CloseMongoDB(client *mongo.Client) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	if err := client.Disconnect(ctx); err != nil {
		log.Printf("Failed to properly disconnect from MongoDB: %s", err)
	}
	log.Println("MongoDB client successfully disconnected")
}
