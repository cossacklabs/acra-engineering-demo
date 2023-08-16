package serialize

import (
	"encoding/json"

	"go.mongodb.org/mongo-driver/bson"
)

func FromBson(sourceData bson.M, target interface{}) error {
	marshalData, err := json.Marshal(sourceData)
	if err != nil {
		return err
	}

	return json.Unmarshal(marshalData, target)
}

func ToBson(data interface{}) (bson.M, error) {
	rawDeploy, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}

	var bsonDoc bson.M
	err = bson.UnmarshalExtJSON(rawDeploy, false, &bsonDoc)
	return bsonDoc, err
}
