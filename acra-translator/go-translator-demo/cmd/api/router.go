package main

import (
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	http_swagger "github.com/swaggo/http-swagger"

	"cossacklabs/acra-translator-demo/cmd/api/config"
	"cossacklabs/acra-translator-demo/cmd/api/handlers"
	"cossacklabs/acra-translator-demo/cmd/api/swagger"
	"cossacklabs/acra-translator-demo/internal/persistence"
	"cossacklabs/acra-translator-demo/internal/pkg/acra-translator"
)

func NewRouter(
	cfg *config.Env,
	db persistence.DB,
	translatorClient acra_translator.Client,
) http.Handler {
	router := chi.NewRouter()
	router.Use(middleware.Logger)
	router.Use(middleware.Recoverer)

	router.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300, // Maximum value not ignored by any of major browsers
	}))

	userHandlers := handlers.NewUser(db, translatorClient)
	router.Route("/", func(r chi.Router) {
		r.Post("/users", userHandlers.Save)
		r.Get("/users/{user_id}", userHandlers.GetByID)
		r.Get("/users/search/{email}", userHandlers.GetByEmail)
		r.Put("/users/{user_id}/docs", userHandlers.UploadUserDocs)
		r.Get("/users/{user_id}/docs", userHandlers.GetUserDocs)
	})

	swaggerHost := cfg.Addr
	if envHost := os.Getenv("SWAGGER_HOST"); envHost != "" {
		swaggerHost = envHost
	}

	swagger.SwaggerInfo.Host = swaggerHost
	router.Get("/swagger/*", http_swagger.Handler(http_swagger.URL("doc.json")))

	log.Printf("Swagger is available on: %s/swagger/index.html#/\n", swagger.SwaggerInfo.Host)

	return router
}
