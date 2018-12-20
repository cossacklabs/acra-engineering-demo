# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('blog', '0002_event'),
    ]

    operations = [
        migrations.AlterField(
            model_name='entry',
            name='author',
            field=models.BinaryField(),
        ),
        migrations.AlterField(
            model_name='entry',
            name='body',
            field=models.BinaryField(),
        ),
        migrations.AlterField(
            model_name='entry',
            name='body_html',
            field=models.BinaryField(),
        ),
        migrations.AlterField(
            model_name='entry',
            name='headline',
            field=models.BinaryField(),
        ),
        migrations.AlterField(
            model_name='entry',
            name='summary',
            field=models.BinaryField(),
        ),
        migrations.AlterField(
            model_name='entry',
            name='summary_html',
            field=models.BinaryField(),
        ),
    ]
