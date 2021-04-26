{
  "service": {
    "id": "web-service-01",
    "name": "front-end-eCommerce",
    "tags": ["v7.01", "production"],
    "address": "192.168.99.111",
    "port": 80,
    "check": {
       "id": "web",
       "name": "Health check",
       "http": "http://localhost:8080/health",
       "method" : "GET",
       "interval": "10s"
     }
}