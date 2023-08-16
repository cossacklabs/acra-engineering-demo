package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"cossacklabs/acra-translator-demo/cmd/api/config"
	"cossacklabs/acra-translator-demo/internal/persistence"
	"cossacklabs/acra-translator-demo/internal/pkg/acra-translator"
	"cossacklabs/acra-translator-demo/pkg/http"
)

//	@title		Go-AcraTranslator Demo
//	@version	0.0.1
//	@Produce	json

func main() {
	cfg := config.Env{}
	OK(config.ParseEnvConfig(&cfg))

	ctx, cancel := context.WithCancel(context.Background())
	RunGracefulShutDownListener(ctx, cancel)

	mongoDB, err := persistence.InitMongoDB(ctx, cfg.MongoDBURL)
	OK(err)

	db := persistence.NewDB(mongoDB)
	translatorHttp, err := acra_translator.NewHTTP(cfg.TlsClientCertPath, cfg.TlsClientKeyPath, cfg.TlsClientCAPath, cfg.AcraTranslatorURL)
	OK(err)

	router := NewRouter(&cfg, db, translatorHttp)

	server := http.NewServer(cfg.Addr, router)

	if err := server.ListenAndServe(ctx); err != nil {
		log.Printf("Failed to serve api %s", err.Error())
	}
}

func OK(err error) {
	if err != nil {
		log.Fatalf("Error: %s\n", err.Error())
	}
}

func RunGracefulShutDownListener(ctx context.Context, cancel context.CancelFunc) context.Context {
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		osCall := <-c
		log.Printf("Stop system call:%+v", osCall)
		cancel()
	}()

	return ctx
}
