package acra_translator

import (
	"bytes"
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
)

type HTTPClient struct {
	translatorURL *url.URL
	client        *http.Client
}

func NewHTTP(certFilePath, keyFile, caFilePath string, translatorURL *url.URL) (HTTPClient, error) {
	// Load client cert
	cert, err := tls.LoadX509KeyPair(certFilePath, keyFile)
	if err != nil {
		return HTTPClient{}, err
	}

	// Load CA cert
	caCert, err := os.ReadFile(caFilePath)
	if err != nil {
		return HTTPClient{}, err
	}

	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// Setup HTTPS client
	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		RootCAs:      caCertPool,
	}
	tlsConfig.BuildNameToCertificate()
	transport := &http.Transport{TLSClientConfig: tlsConfig}
	return HTTPClient{
		client:        &http.Client{Transport: transport},
		translatorURL: translatorURL,
	}, nil
}

func (c HTTPClient) GenerateQueryHash(data []byte) (GenQueryHashResponse, error) {
	b64Encoded := base64.StdEncoding.EncodeToString(data)
	request := Base{
		Data: b64Encoded,
	}

	var response GenQueryHashResponse
	if err := c.makeTranslatorRequest("/v2/generateQueryHash", request, &response); err != nil {
		return GenQueryHashResponse{}, err
	}
	return response, nil
}

func (c HTTPClient) EncryptSearchable(data []byte) (EncryptResponse, error) {
	b64Encoded := base64.StdEncoding.EncodeToString(data)
	request := Base{
		Data: b64Encoded,
	}

	var response EncryptResponse
	if err := c.makeTranslatorRequest("/v2/encryptSymSearchable", request, &response); err != nil {
		return EncryptResponse{}, err
	}
	return response, nil
}

func (c HTTPClient) DecryptSearchable(cipherText []byte) (DecryptResponse, error) {
	request := Base{
		Data: string(cipherText),
	}

	var response DecryptResponse
	if err := c.makeTranslatorRequest("/v2/decryptSymSearchable", request, &response); err != nil {
		return DecryptResponse{}, err
	}
	return response, nil
}

func (c HTTPClient) Encrypt(data []byte) (EncryptResponse, error) {
	b64Encoded := base64.StdEncoding.EncodeToString(data)
	request := Base{
		Data: b64Encoded,
	}

	var response EncryptResponse
	if err := c.makeTranslatorRequest("/v2/encrypt", request, &response); err != nil {
		return EncryptResponse{}, err
	}
	return response, nil
}

func (c HTTPClient) Decrypt(cipherText []byte) (DecryptResponse, error) {
	request := Base{
		Data: string(cipherText),
	}

	var response DecryptResponse
	if err := c.makeTranslatorRequest("/v2/decrypt", request, &response); err != nil {
		return DecryptResponse{}, err
	}
	return response, nil
}

func (c HTTPClient) makeTranslatorRequest(reqPath string, body, target interface{}) error {
	rawBody, err := json.Marshal(body)
	if err != nil {
		return err
	}

	// Do POST something
	resp, err := c.client.Post(c.translatorURL.String()+reqPath, "application/json", bytes.NewReader(rawBody))
	if err != nil {
		return err
	}

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("expected 200 OK status on translator request, got %d", resp.StatusCode)
	}

	defer resp.Body.Close()

	res, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(res, &target); err != nil {
		return err
	}
	return nil
}
