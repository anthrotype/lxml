PYTHON?=python
TESTFLAGS=-p -v
TESTOPTS=
SETUPFLAGS=
LXMLVERSION=`cat version.txt`

all: inplace

# Build in-place
inplace:
	$(PYTHON) setup.py $(SETUPFLAGS) build_ext -i

build:
	$(PYTHON) setup.py $(SETUPFLAGS) build

test_build: build
	$(PYTHON) test.py $(TESTFLAGS) $(TESTOPTS)

test_inplace: inplace
	$(PYTHON) test.py $(TESTFLAGS) $(TESTOPTS)
	PYTHONPATH=src $(PYTHON) selftest.py
	PYTHONPATH=src $(PYTHON) selftest2.py

valgrind_test_inplace: inplace
	valgrind --tool=memcheck --leak-check=full --num-callers=30 --suppressions=valgrind-python.supp \
		$(PYTHON) test.py

gdb_test_inplace: inplace
	@echo -e "file $(PYTHON)\nrun test.py" > .gdb.command
	gdb -x .gdb.command -d src -d src/lxml

bench_inplace: inplace
	$(PYTHON) benchmark/bench_etree.py -i
	$(PYTHON) benchmark/bench_xpath.py -i
	$(PYTHON) benchmark/bench_xslt.py -i
	$(PYTHON) benchmark/bench_objectify.py -i

ftest_build: build
	$(PYTHON) test.py -f $(TESTFLAGS) $(TESTOPTS)

ftest_inplace: inplace
	$(PYTHON) test.py -f $(TESTFLAGS) $(TESTOPTS)

html: inplace
	PYTHONPATH=src $(PYTHON) doc/mkhtml.py doc/html . ${LXMLVERSION}
	rm -fr doc/html/api
	@[ -x "`which epydoc`" ] \
		&& (cd src && echo "Generating API docs ..." && \
			PYTHONPATH=. epydoc -v --docformat "restructuredtext en" \
			-o ../doc/html/api --no-private --exclude='[.]html[.]tests|[.]_' \
			--name lxml --url http://codespeak.net/lxml/ lxml/) \
		|| (echo "not generating epydoc API documentation")

pdf:
	$(PYTHON) doc/mklatex.py doc/pdf . ${LXMLVERSION}
	(cd doc/pdf && pdflatex lxmldoc.tex && pdflatex lxmldoc.tex)
	@echo "PDF available as doc/pdf/lxmldoc.pdf"

# Two pdflatex runs are needed to build the correct Table of contents.

test: test_inplace

valtest: valgrind_test_inplace

gdbtest: gdb_test_inplace

bench: bench_inplace

ftest: ftest_inplace

clean:
	find . \( -name '*.o' -o -name '*.so' -o -name '*.py[cod]' -o -name '*.dll' \) -exec rm -f {} \;
	rm -rf build

docclean:
	rm -f doc/html/*.html
	rm -fr doc/html/api

realclean: clean docclean
	find . -name '*.c' -exec rm -f {} \;
	rm -f TAGS
	$(PYTHON) setup.py clean -a
