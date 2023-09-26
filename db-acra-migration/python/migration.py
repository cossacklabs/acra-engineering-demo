# Copyright 2023, Cossack Labs Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# coding: utf-8
import argparse
import io
from sqlalchemy import (Table, Column, Integer, MetaData, select, update, Text, asc)
from sqlalchemy.orm import Session
from sqlalchemy.sql import text

from common import get_engine, register_common_cli_params

metadata = MetaData()
user_table = Table(
    'users', metadata,
    Column('id', Integer, primary_key=True, nullable=False),
    Column('phone_number', Text, nullable=False),
    Column('ssn', Text, nullable=False),
    Column('email', Text, nullable=False),
    Column('firstname', Text, nullable=False),
    Column('lastname', Text, nullable=False),
    Column('age', Integer, nullable=False),
)


def generate_data(engine, csv_string):
    with Session(engine) as session:
        with session.connection() as conn:
            with conn.connection.cursor() as cursor:
                sql = 'COPY users (id,phone_number,ssn,email,firstname,lastname,age) FROM STDIN WITH (FORMAT CSV, HEADER)'
                cursor.copy_expert(sql, io.StringIO(csv_string))
                session.commit()
    print("Data generated successfully!")


def print_data(connection, table=user_table):
    """fetch data from database and print to console"""
    query = text('SELECT * FROM users ORDER BY users.id ASC LIMIT 10')
    print("Fetch data by query: \n", query)

    result = connection.execute(query)
    result = result.fetchall()

    # print(len(result))
    for row in result:
        values = ['{:<3}'.format(row['id'])]
        for col in row[1:]:
            if isinstance(col, memoryview):
                values.append(col.tobytes().decode("utf-8"))
            else:
                values.append(str(col))

        print(' - '.join(values))

def migrate_data(connection, table=user_table):
    count_query = text('SELECT count(*) FROM users')
    count = connection.execute(count_query).fetchone()[0]
    print("Running migration for {} rows:".format(count))

    offset = 0
    step = 100
    while offset < count:
        query = text('SELECT * FROM users ORDER BY users.id ASC LIMIT {} OFFSET {}'.format(step, offset))
        users = connection.execute(query).fetchall()

        for user in users:
            update_query = update(user_table).values(
                phone_number=user["phone_number"].tobytes().decode("utf-8"),
                ssn=user["ssn"].tobytes().decode("utf-8"),
                firstname=user["firstname"].tobytes().decode("utf-8"),
                lastname=user["lastname"].tobytes().decode("utf-8"),
                email=user["email"],
            ).where(user_table.c.id == user["id"])
            connection.execute(update_query)

        print("Migrated {} items".format(offset))
        offset += step


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    register_common_cli_params(parser)
    args = parser.parse_args()

    engine = get_engine(
        db_host=args.host, db_port=args.port, db_user=args.db_user, db_password=args.db_password,
        db_name=args.db_name, is_mysql=args.mysql, is_postgresql=args.postgresql,
        tls_ca=args.tls_root_cert, tls_key=args.tls_key, tls_crt=args.tls_cert,
        sslmode=args.ssl_mode, verbose=args.verbose)
    connection = engine.connect()
    metadata.create_all(engine)

    if args.generate:
        with open('users.csv', 'r') as file:
            users_data = file.read()
            generate_data(engine, users_data)
    elif args.migrate:
        migrate_data(connection)
    elif args.print:
        print_data(connection)
    else:
        print('Use --generate or --migrate or --print options')
        exit(1)
