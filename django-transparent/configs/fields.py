from django.db import models
from django.utils.translation import gettext_lazy as _
import codecs


class PgTextBinaryField(models.TextField):
    description = _("Text as binary data")

    def from_db_value(self, value, expression, connection):
        return db_value_to_string(value)

    def get_db_prep_value(self, value, connection, prepared=False):
        return string_to_dbvalue(value)


class PgCharBinaryField(models.CharField):
    description = _("Chars as binary data")

    def from_db_value(self, value, expression, connection):
        return db_value_to_string(value)

    def get_db_prep_value(self, value, connection, prepared=False):
        return string_to_dbvalue(value)


def bytes_to_string(b):
    if len(b) >= 2 and b[0:2] == b'\\x':
        return codecs.decode(b[2:].decode(), 'hex').decode('utf-8')

    return b.decode()


def memoryview_to_string(mv):
    return bytes_to_string(mv.tobytes())


def db_value_to_string(value):
    if isinstance(value, memoryview):
        return memoryview_to_string(value)
    elif isinstance(value, bytes) or isinstance(value, bytearray):
        return bytes_to_string(value)

    return value


def string_to_dbvalue(s):
    if s == '':
        return b''
    elif s is None:
        return None

    return '\\x{}'.format(bytes(s, 'utf-8').hex()).encode('ascii')