package acra_translator

type (
	Base struct {
		Data string `json:"data"`
	}

	EncryptResponse      Base
	DecryptResponse      Base
	GenQueryHashResponse Base
)

type Client interface {
	Encrypt(data []byte) (EncryptResponse, error)
	EncryptSearchable(data []byte) (EncryptResponse, error)
	Decrypt(cipherText []byte) (DecryptResponse, error)
	DecryptSearchable(cipherText []byte) (DecryptResponse, error)
	GenerateQueryHash(data []byte) (GenQueryHashResponse, error)
}
