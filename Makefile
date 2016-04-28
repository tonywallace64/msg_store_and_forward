# Author Tony Wallace

all: ebin/mailbox.beam
ebin/%.beam: src/%.erl
	erlc -o ebin $< 

.PHONY: clean
clean:
	-rm  ebin/*.beam


