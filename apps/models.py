from django.contrib.auth.base_user import BaseUserManager, AbstractBaseUser
from django.db import models


class UserManager(BaseUserManager):
    def create_user(self, username, password, **kwargs):
        user = self.model(username=username, **kwargs)
        user.set_password(password)
        user.save(using=self._db)

        return user

    def create_superuser(self, username, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        return self.create_user(username, password, **extra_fields)


class User(AbstractBaseUser):
    id = models.BigAutoField(primary_key=True)
    username = models.CharField(max_length=100, null=False)
    phone_number = models.CharField(max_length=20, null=False)

    is_staff = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_superuser = models.BooleanField(default=False)

    objects = UserManager()
    USERNAME_FIELD = 'username'

class Accommodation(models.Model):
    id = models.BigAutoField(primary_key=True) # PK
    name = models.CharField(max_length=100, null=False) # 숙소명
    number = models.CharField(max_length=20, default='000-0000-0000') # 숙소 전화번호
    address = models.CharField(max_length=100, null=False) # 주소
    # no_of_rooms = models.CharField(max_length=50, null=False) # 객실 수
    # urls = models.CharField(max_length=100) # 홈페이지 주소
    price = models.IntegerField(default=0) # 객실 가격
    like = models.ManyToManyField(User, related_name='likes', blank=True)  # 좋아요 기능
    ranks = models.DecimalField(max_digits=3, decimal_places=1, default=0.0)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

class Review(models.Model):
    id = models.BigAutoField(primary_key=True)
    accommodation = models.ForeignKey(Accommodation, on_delete=models.CASCADE, related_name="reviews")
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    content = models.TextField()
    rating = models.DecimalField(max_digits=2, decimal_places=1, null=True, blank=True)
    created_at = models.DateTimeField(auto_now=True)
    updated_at = models.DateTimeField(auto_now=True)

class Reservation(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # 예약한 사용자
    accommodation = models.ForeignKey(Accommodation, on_delete=models.CASCADE)
    check_in_date = models.DateField() # 체크인 날짜
    check_out_date = models.DateField() # 체크아웃 날짜
    status = models.BooleanField() # 예약 유무
    price = models.IntegerField(default=0) # 객실 가격
    create_at = models.DateField() # 예약 날짜
    updated_at = models.DateField() # 갱신 날짜



