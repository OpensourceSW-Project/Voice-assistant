# Generated by Django 5.1.3 on 2024-11-21 13:36

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('apps', '0006_accommodation_latitude_accommodation_longitude'),
    ]

    operations = [
        migrations.RenameField(
            model_name='reservation',
            old_name='accomodation',
            new_name='accommodation',
        ),
    ]