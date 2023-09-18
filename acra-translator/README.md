# AcraTranslator usage

Learn more details
about [AcraTranslator](https://docs.cossacklabs.com/acra/acra-in-depth/architecture/acratranslator/#acratranslator-an-api-service)
architecture.

## 1. Installation

```bash
$ curl https://raw.githubusercontent.com/cossacklabs/acra-engineering-demo/master/run.sh | \
    bash -s -- acra-translator
```

This command downloads a simple Go API Server application, AcraTranslator, MongoDB, sets up the environment, configures
Go application to encrypt data with AcraTranslator and store to MongoDB, and provides an
API (Swagger) or [Postman Collection](./acra-translator/go-translator-demo/swagger/translator-demo.postman_collection.json) for you to try.

## 2. What's inside

<p align="center"><img src="../_pics/translator-demo.png" alt="Go API Server, MongoDB, AcraTranslator architecture" width="560"></p>

**The client-side application** is a simple [Go API server](./acra-translator/go-translator-demo)
that works with a database. The Go API server talks with the database and **AcraTranslator** (via TLS). AcraTranslator **encrypts** the incoming plaintext data, and decrypts the encrypted data. Go API server is responsible to call AcraTranslator and to talk with the database.

### 2.1 Insert data

Currently, Go API server operates with `User` model:

```
type User struct {
	ID              string    
	Firstname       string     `*encrypted*`
	Surname         string     `*encrypted*`
	Zipcode         int32      `*tokenized*`
	Email           string     `*encrypted-searchable*` 
	City            string     
	ResidentCountry string      
	Citizenship     string      
	PhoneNumber     string    
	Notes           string    
	DocPath         *string    
	Birthday        time.Time  
}
```

To insert data, run:

```bash
$ curl -X 'POST' \
  'http://localhost:8008/users' \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "birthday": "2023-08-18T08:19:19.816Z",
  "citizenship": "string",
  "city": "string",
  "doc_path": "",
  "email": "test@gmail.com",
  "firstname": "test_name",
  "id": "string",
  "notes": "string",
  "phone_number": "string",
  "resident_country": "string",
  "surname": "test_name",
  "zipcode": 12345
}'
```

Response should contain encrypted data and generated `id`:

```
{
   "data": {
      "id": "0dbcf7d4-e392-4343-a734-e5cf21d3a8a1",
      "firstname": "JSUl0gAAAAAAAADxIiIiIiIiIiJVRUMyAAAALTSaoe8DAbcekMuefGOVaHh6NFTIxG+9p/Mfesc4fjhsRfit1KIgJwQmVAAAAAABAUAMAAAAEAAAACAAAADUyyUrRNMyX8/PAB41JfPjKcE9SabQ0HavLS5/c5EK0gufrhY6jm1cedjet8VgRysCylVjnPgwklcnqjM1AAAAAAAAAAABAUAMAAAAEAAAAAkAAADw8XpRuyx402lAj9mAidHV6L20ZZI/bYxlaY2HZ0YEZkOTHjn+",
      "surname": "JSUl0gAAAAAAAADxIiIiIiIiIiJVRUMyAAAALT7unFkC+MAG++BMKn244P7aEDzCz6lXoPyzGxGh9ADk46mJFIUgJwQmVAAAAAABAUAMAAAAEAAAACAAAADXrFhjVuB7hh/t49ZSsbmuvUujzkzly/w9fyRrT1nTmqU3BBfkqVeYJE9deLWVmJsCscwC82ZLCPhKrvs1AAAAAAAAAAABAUAMAAAAEAAAAAkAAADvyNVyouPV4XicLncCeG31zLH41RgYxfE73qaU9W0ZECj+Hy1G",
      "zipcode": 178850713,
      .....
   }
}
```

### 2.2 Read data

To read the data by `id`, use the id value received from the insert response:

```bash
$ curl -X 'GET' \
  'http://localhost:8008/users/{id-from-response}' \
  -H 'accept: application/json'
```

The data should be decrypted:

```
{
   "data": {
      "firstname": "test_name",
      "surname": "test_name",
      "zipcode": 12345,
      ...
   }
}
```

AcraTranslator logs should contain info about successful decryption of the data:

```bash
docker logs --tail 50  acra-translator_acra-translator_1
...

2023/08/18 - 08:38:55 | 200 |     138.314µs |      172.26.0.3 | POST     "/v2/decryptSymSearchable"
2023/08/18 - 08:38:55 | 200 |      123.47µs |      172.26.0.3 | POST     "/v2/detokenize"
```

### 2.2 Search encrypted data

Data could be read by searchable data, stored encrypted in DB.

Server will call the translator to get searchable hash and then read the data from the DB:
```
	mongo.Pipeline{
		{
			{"$match", bson.D{{
				Key: "$expr",
				Value: bson.D{{
					Key: "$eq",
					Value: bson.A{bson.D{{
						Key:   "$substr",
						Value: []interface{}{"$email", 0, len(emailSearchHash)},
					}}, email}},
				}},
			}}},
	}
```

```bash
curl -X 'GET' \
  'http://localhost:8008/users/search/{email-from-insert-request}' \
  -H 'accept: application/json'
```

The data should be decrypted:

```
{
   "data": {
      "firstname": "test_name",
      "surname": "test_name",
      "zipcode": 12345,
      ...
   }
}
```


### 2.4 File encryption

AcraTranslator could be also used for file encryption/decryption.

```bash
curl -X 'PUT' \
  'http://localhost:8008/users/{user-id}/docs' \
  -H 'Accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'file=@image.png;type=image/png'
```

You should be able to see the path of encrypted file stored on file system under `data.doc_path`:

```
{
  "data": {
    "doc_path": "/tmp/0dbcf7d4-e392-4343-a734-e5cf21d3a8a1495524684",
  }
}
```

To see the actual content of the file:

```
docker exec -it acra-translator_go-api-server_1 cat /tmp/0dbcf7d4-e392-4343-a734-e5cf21d3a8a1495524684
```

You should see the base64 encoded gibberish on the screen.

To decrypt the file, just call:

```
curl -X 'GET' \
  'http://localhost:8008/users/{user-id}/docs' \
  -H 'accept: multipart/' > image.png
```

The `image.png` should contain the same file that was uploaded and encrypted.

### 2.5 Read data from the database

To jump to MongoDB cli interface:

```
docker exec -it acra-translator_mongo_1 mongosh "mongodb://root:password@mongo:27017/admin?authSource=admin"
```

Run command to see the actual state of the data stored in DB:

```
db.users.find()
```

Playground also contains the WebUI connected to MongoDB. Its available on `http://localhost:8081/` with BasicAuth:
*test*/*test*.

---
