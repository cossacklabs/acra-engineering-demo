from binascii import hexlify
from django.db import models
from django.utils.translation import gettext_lazy as _

class TextBinaryField(models.TextField):
    description = _("Text as binary data")

    def from_db_value(self, value, expression, connection):

        if isinstance(value, memoryview):
            return value.tobytes().decode('utf-8')
        elif isinstance(value, bytes) or isinstance(value, bytearray):
            return value.decode('utf-8')

        return value

    def get_db_prep_value(self, value, connection, prepared=False):
        if value == '':
            return b''
        elif value is None:
            return None
        else:
            return '\\x{}'.format(bytes(value, 'utf-8').hex()).encode('ascii')


class CharBinaryField(models.CharField):
    description = _("Chars as binary data")

    def from_db_value(self, value, expression, connection):

        if isinstance(value, memoryview):
            return value.tobytes().decode('utf-8')
        elif isinstance(value, bytes) or isinstance(value, bytearray):
            return value.decode('utf-8')

        return value

    def get_db_prep_value(self, value, connection, prepared=False):
        if value == '':
            return b''
        elif value is None:
            return None
        else:
            return '\\x{}'.format(bytes(value, 'utf-8').hex()).encode('ascii')
