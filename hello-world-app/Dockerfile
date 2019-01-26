FROM golang
ADD . /go/src/github.com/CampGareth/AND-Digital-Terraform-Test/hello-world-app
RUN go get github.com/gin-gonic/gin
RUN go get github.com/caarlos0/env
RUN go install /go/src/github.com/CampGareth/AND-Digital-Terraform-Test/hello-world-app
ENTRYPOINT /go/bin/hello-world-app
EXPOSE 8080