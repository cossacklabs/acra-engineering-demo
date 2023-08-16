package http

import (
	"context"
	"log"
	"net"
	"net/http"
	"time"
)

type ServerAddress string

type Server struct {
	addr    string
	handler http.Handler
}

func NewServer(addr string, handler http.Handler) Server {
	return Server{
		addr, handler,
	}
}

func (s *Server) ListenAndServe(ctx context.Context) error {
	server := http.Server{
		Addr:              s.addr,
		Handler:           s.handler,
		ReadHeaderTimeout: time.Minute,
	}

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Printf("api listen err: %s\n", err)
		}
	}()

	log.Printf("Server start listnening on: %s\n", s.addr)
	<-ctx.Done()

	log.Println("Stopping api...")

	ctxShutDown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctxShutDown); err != nil {
		log.Printf("server Shutdown Failed: %s", err)
	}
	log.Println("Server Graceful shutdown success")

	return nil
}

func (a *ServerAddress) UnmarshalText(addr []byte) error {
	_, _, err := net.SplitHostPort(string(addr))
	*a = ServerAddress(addr)
	return err
}
