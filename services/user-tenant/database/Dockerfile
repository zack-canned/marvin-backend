FROM postgres:18.1-trixie

ENV HOME=/db
ENV PORT=5432

WORKDIR ${HOME}
    
COPY ./init.sql /docker-entrypoint-initdb.d/

EXPOSE ${PORT}

CMD ["postgres"]
