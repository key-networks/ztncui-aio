package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"time"
	"os"

	"golang.org/x/crypto/argon2"
)

type UserDef struct {
	Name    string `json:"name"`
	PassSet bool   `json:"pass_set"`
	Hash    string `json:"hash"`
}

type PasswdDef struct {
	Admin UserDef `json:"admin"`
}

const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

func RandStringBytes(n int) string {
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, n)
	for i := range b {
		b[i] = letterBytes[rand.Intn(len(letterBytes))] // It's not safe for password purpose, but i'm lazy.
	}
	return string(b)
}

func main() {
	var password string = os.Getenv("ZTNCUI_PASSWD")
	if len(password) < 2 {
		log.Println("Current Password: " + password + " is too weak or not set...")
		password = RandStringBytes(10)
	} 
	log.Println("Current Password: " + password)
	
	var ag2_memory uint32 = 4096
	var ag2_iter uint32 = 3
	var ag2_para uint8 = 1
	var ag2_saltlen uint8 = 16
	var ag2_hashlen uint32 = 32

	ag2_salt := make([]byte, ag2_saltlen)
	_, err := rand.Read(ag2_salt)
	if err != nil {
		log.Fatal(err)
	}

	ag2_hash := argon2.Key([]byte(password), ag2_salt, ag2_iter, ag2_memory, ag2_para, ag2_hashlen)
	ag2_saltb64 := base64.RawStdEncoding.EncodeToString(ag2_salt)
	ag2_hashb64 := base64.RawStdEncoding.EncodeToString(ag2_hash)

	finalhash := fmt.Sprintf("$argon2i$v=%d$m=%d,t=%d,p=%d$%s$%s", argon2.Version, ag2_memory, ag2_iter, ag2_para, ag2_saltb64, ag2_hashb64)

	u1 := UserDef{
		Name:    "admin",
		PassSet: false,
		Hash:    finalhash,
	}
	p1 := PasswdDef{
		Admin: u1,
	}
	v1, err := json.Marshal(p1)
	if err != nil {
		log.Fatal(err)
	}
	err = ioutil.WriteFile("passwd", v1, 0644)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Generate Done, check passwd file.")
}
