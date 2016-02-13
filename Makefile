#
#  Makefile for Go
#

# Global environment variables
MAKEFLAGS := -j 1

# Define commands
GO_CMD := go

# Enable verbose
VERBOSE_GO := -v

# Build
GO_BUILD=${GO_CMD} build ${VERBOSE_GO} -o ${OUTPUT}
GO_BUILD_RACE=${GO_CMD} build ${VERBOSE_GO} -race -o ${OUTPUT}
# Install
GO_INSTALL=${GO_CMD} install ${VERBOSE_GO}
# Test
GO_TEST=${GO_CMD} test ${VERBOSE_GO}
GO_TEST_RUN=${GO_TEST} -run ${RUN}
GO_TEST_ALL=test -race -cover -bench=.
# Lint
GO_VET=${GO_CMD} vet
GO_LINT=golint
# Vendor management
GODEP := ${GOPATH}/bin/godep
GODEP_CMD := $(if ${GODEP}, , $(error Please install godep: go get github.com/tools/godep)) ${GODEP}
# Misc
GO_RUN=${GO_CMD} run
GO_CLEAN=${GO_CMD} clean


# Set debug gcflag, or optimize ldflags
# See http://goo.gl/6QCJMj
#   Usage: GDBDEBUG=1 make
ifeq ($(DEBUG),true)
	GO_GCFLAGS := -gcflags "-N -l"
else
	GO_LDFLAGS := $(GO_LDFLAGS) -w -s
endif


# Parse git current branch commit-hash
GO_LDFLAGS := ${GO_LDFLAGS} -X main.GitCommit=`git rev-parse --short HEAD 2>/dev/null`

CGO_CFLAGS := 
CGO_LDFLAGS := 


#
# Package side settings
#
# Build package infomation
GITHUB_USER := zchee
TOP_PACKAGE_DIR := github.com/${GITHUB_USER}
PACKAGE := `basename $(PWD)`
OUTPUT := bin/$(PACKAGE)
# Parse "func main()" only '.go' file on current dir
# FIXME: Not support main.go
MAIN_FILE := `grep "func main\(\)" *.go -l`


# Colorable output
CRESET := \x1b[0m
CBLACK := \x1b[30;01m
CRED := \x1b[31;01m
CGREEN := \x1b[32;01m
CYELLOW := \x1b[33;01m
CBLUE := \x1b[34;01m
CMAGENTA := \x1b[35;01m
CCYAN := \x1b[36;01m
CWHITE := \x1b[37;01m


#
# Build jobs settings
#
default: build

build:
	@test -d bin || mkdir -p bin;
	@echo "${CBLUE}==>${CRESET} Build ${CGREEN}${PACKAGE}${CRESET}..."
	@echo "${CBLACK} GODEBUG=cgocheck=0 CGO_CFLAGS=${CGO_CFLAGS} CGO_LDFLAGS=${CGO_LDFLAGS} ${GO_BUILD} -ldflags "$(GO_LDFLAGS)" ${GO_GCFLAGS} ${TOP_PACKAGE_DIR}/${PACKAGE} ${CRESET}"; \
	GODEBUG=cgocheck=0 CGO_CFLAGS=${CGO_CFLAGS} CGO_LDFLAGS=${CGO_LDFLAGS} ${GO_BUILD} -ldflags "$(GO_LDFLAGS)" ${GO_GCFLAGS} ${TOP_PACKAGE_DIR}/${PACKAGE} || exit 1

install:
	@echo "${CBLUE}==>${CRESET} Install ${CGREEN}${PACKAGE}${CRESET}..."
	@echo "${CBLACK} GODEBUG=cgocheck=0 CGO_CFLAGS=${CGO_CFLAGS} CGO_LDFLAGS=${CGO_LDFLAGS} ${GO_INSTALL} -ldflags "$(GO_LDFLAGS)" ${GO_GCFLAGS} ${TOP_PACKAGE_DIR}/${PACKAGE} ${CRESET}"; \
	GODEBUG=cgocheck=0 CGO_CFLAGS=${CGO_CFLAGS} CGO_LDFLAGS=${CGO_LDFLAGS} ${GO_INSTALL} -ldflags "$(GO_LDFLAGS)" ${GO_GCFLAGS} ${TOP_PACKAGE_DIR}/${PACKAGE} || exit 1


test:
	@echo "${CBLUE}==>${CRESET} Test ${CGREEN}${PACKAGE}${CRESET}..."
	@echo "${CBLACK} ${GO_TEST} ${TOP_PACKAGE_DIR}/${PACKAGE}/xhyve ${CRESET}"; \
	${GO_TEST} ${TOP_PACKAGE_DIR}/${PACKAGE}/xhyve || exit 1

test-run:
	@echo "${CBLUE}==>${CRESET} Test ${CGREEN}${PACKAGE} ${FUNC} only${CRESET}..."
	@echo "${CBLACK} ${GO_TEST_RUN} ${TOP_PACKAGE_DIR}/${PACKAGE}/xhyve ${CRESET}"; \
	${GO_TEST_RUN} ${TOP_PACKAGE_DIR}/${PACKAGE}/xhyve || exit 1

dep-save:
	${GODEP_CMD} save $(shell go list ./... | grep -v vendor/)

dep-restore:
	${GODEP_CMD} restore -v

clean:
	@${RM} -r ./bin

.PHONY: clean build
