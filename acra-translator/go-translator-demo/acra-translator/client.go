package acra_translator

type (
	Base struct {
		Data string `json:"data"`
	}

	EncryptResponse      Base
	DecryptResponse      Base
	GenQueryHashResponse Base

	TokenizeResponse struct {
		Data interface{} `json:"data"`
	}
)

type TokenType uint8

const (
	TokenTypeInt32 = iota + 1
	TokenTypeInt64
	TokenTypeString
	TokenTypeBinary
	TokenTypeEmail
)

type Client interface {
	Encrypt(data []byte) (EncryptResponse, error)
	EncryptSearchable(data []byte) (EncryptResponse, error)
	Tokenize(data interface{}, tokenType TokenType) (TokenizeResponse, error)
	Detokenize(data interface{}, tokenType TokenType) (TokenizeResponse, error)
	Decrypt(cipherText []byte) (DecryptResponse, error)
	DecryptSearchable(cipherText []byte) (DecryptResponse, error)
	GenerateQueryHash(data []byte) (GenQueryHashResponse, error)
}
