package main

import (
	"fmt"

	"github.com/caarlos0/env"
	"github.com/gin-gonic/gin"
)

type Config struct {
	Environment string `env:"ENVIRONMENT" envDefault:"dev"`
	ServerName  string `env:"SERVER_NAME"`
}

func main() {
	cfg := Config{}
	err := env.Parse(&cfg)
	if err != nil {
		fmt.Println("Error encountered while parsing config from environment")
	}

	r := gin.Default()
	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"Environment": cfg.Environment,
			"Server":      cfg.ServerName,
		})
	})

	r.Run()
}
