package config

import (
	"log"
	"net/url"

	"github.com/caarlos0/env/v6"
	"github.com/joho/godotenv"
	"go.uber.org/zap/zapcore"
)

const EnvFile = ".env"

type Config interface {
	Parse() error
}

type Env struct {
	Addr     string        `env:"ADDRESS,required"`
	LogLevel zapcore.Level `env:"LOG_LEVEL" envDefault:"info"`

	MongoDBURL        *url.URL `env:"MONGODB_CONNECTION_URL,required"`
	AcraTranslatorURL *url.URL `env:"ACRA_TRANSLATOR_URL,required"`
	TlsClientCertPath string   `env:"TLS_CLIENT_CERT_PATH,required"`
	TlsClientKeyPath  string   `env:"TLS_CLIENT_KEY_PATH,required"`
	TlsClientCAPath   string   `env:"TLS_CLIENT_CA_PATH,required"`
}

func (e *Env) Parse() error {
	err := env.Parse(e)
	if err != nil {
		return err
	}

	return nil
}

func ParseEnvConfig(config Config) error {
	if err := godotenv.Load(EnvFile); err != nil {
		log.Printf("cant load from .env %s, trying load from ENV\n", err.Error())
	}

	return config.Parse()
}
