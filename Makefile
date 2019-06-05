.PHONY: all clean test dialyzer

all: priv static

priv:
	mkdir -p priv

static: priv/
	ln -fs ../static priv/

clean:
	$(RM) -r priv

test:
	mix test

dialyzer:
	mix dialyzer --halt-exit-status