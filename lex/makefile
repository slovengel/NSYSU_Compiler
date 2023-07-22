FILE_lex = B093040024.l
PROG_lex = lex.yy.c
all:	$(PROG_lex)
	gcc $(PROG_lex) -o demo -lfl

$(PROG_lex):	$(FILE_lex)
	flex $(FILE_lex)

clean:
	rm demo $(PROG_lex)
	
	
	
	
