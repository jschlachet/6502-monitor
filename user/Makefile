BUILD_DIR=build
BIN_DIR=bin

all:
	make -C bin

clean:
	/bin/rm -f $(BUILD_DIR)/*.o  && \
	/usr/bin/find $(BIN_DIR) -type f ! -name Makefile ! -name README.md -delete 
