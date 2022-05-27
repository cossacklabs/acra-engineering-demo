from __future__ import unicode_literals

from django.db import migrations


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        ('dashboard', '0002_delete_rssfeedmetric_create_githubsearchcountmetric'),
    ]

    operations = [
        migrations.RunSQL(
            'ALTER TABLE dashboard_category DROP constraint dashboard_category_position_check'
        ),
        migrations.RunSQL(
            "ALTER TABLE dashboard_category ALTER COLUMN position TYPE bytea USING position::text::bytea"
        )
    ]
