package main

import (
	"context"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"syscall"

	"github.com/caarlos0/env/v6"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	http_swagger "github.com/swaggo/http-swagger"

	"cossacklabs/acra-translator-demo/acra-translator"
	"cossacklabs/acra-translator-demo/handlers"
	pkg_http "cossacklabs/acra-translator-demo/pkg/http"
	"cossacklabs/acra-translator-demo/repositories"
	"cossacklabs/acra-translator-demo/swagger"
)

type EnvConfig struct {
	Addr              string   `env:"ADDRESS,required"`
	MongoDBURL        *url.URL `env:"MONGODB_CONNECTION_URL,required"`
	AcraTranslatorURL *url.URL `env:"ACRA_TRANSLATOR_URL,required"`
	TlsClientCertPath string   `env:"TLS_CLIENT_CERT_PATH,required"`
	TlsClientKeyPath  string   `env:"TLS_CLIENT_KEY_PATH,required"`
	TlsClientCAPath   string   `env:"TLS_CLIENT_CA_PATH,required"`
}

func (e *EnvConfig) Parse() error {
	err := env.Parse(e)
	if err != nil {
		return err
	}

	return nil
}

//	@title		Go-AcraTranslator Demo
//	@version	0.0.1
//	@Produce	json

func main() {
	cfg := EnvConfig{}
	OK(cfg.Parse())

	ctx, cancel := context.WithCancel(context.Background())
	runGracefulShutDownListener(ctx, cancel)

	mongoDB, err := repositories.InitMongoDB(ctx, cfg.MongoDBURL)
	OK(err)
	defer repositories.CloseMongoDB(mongoDB.Client())

	userRepo := repositories.NewUser(mongoDB)

	translatorHttp, err := acra_translator.NewHTTP(cfg.TlsClientCertPath, cfg.TlsClientKeyPath, cfg.TlsClientCAPath, cfg.AcraTranslatorURL)
	OK(err)

	router := newRouter(&cfg, userRepo, translatorHttp)

	server := pkg_http.NewServer(cfg.Addr, router)

	if err := server.ListenAndServe(ctx); err != nil {
		log.Printf("Failed to serve api %s", err.Error())
	}
}

func OK(err error) {
	if err != nil {
		log.Fatalf("Error: %s\n", err.Error())
	}
}

func runGracefulShutDownListener(ctx context.Context, cancel context.CancelFunc) context.Context {
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		osCall := <-c
		log.Printf("Stop system call:%+v", osCall)
		cancel()
	}()

	return ctx
}

func newRouter(
	cfg *EnvConfig,
	userRepo repositories.User,
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

	userHandlers := handlers.NewUser(userRepo, translatorClient)
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
