from django.contrib.auth.base_user import BaseUserManager, AbstractBaseUser
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class UserManager(BaseUserManager):
    def _set_defaults(self, **extra_fields):    # 중복되는 부분을 pythonic하게 개선, High-Order Function(재사용)
        extra_fields.setdefault('is_staff', False)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('is_superuser', False)
        return extra_fields

    def create_user(self, username, password, **kwargs):    # **kwargs로 불필요한 인수 사용 방지
        kwargs = self._set_defaults(**kwargs)
        user = self.model(username=username, **kwargs)
        user.set_password(password)
        user.save(using=self._db)

        return user

    def create_superuser(self, username, password=None, **extra_fields):
        extra_fields = self._set_defaults(is_staff=True, is_superuser=True, **extra_fields)

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
    price = models.IntegerField(
        default=0,
        validators=[MinValueValidator(0, message="Price는 음수가 아니여야 합니다.")] # 지능형 리스트 사용, 유효성 검사
    )
    like = models.ManyToManyField(User, related_name='likes', blank=True)  # 좋아요 기능
    ranks = models.DecimalField(max_digits=3, decimal_places=1, default=0.0)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

class Review(models.Model):
    id = models.BigAutoField(primary_key=True)
    accommodation = models.ForeignKey(Accommodation, on_delete=models.CASCADE, related_name="reviews")
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    content = models.TextField()
    rating = models.DecimalField(
        max_digits=2,
        decimal_places=1,
        null=True,
        blank=True,
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)] # 지능형 리스트 사용, rating은 0.0~5.0만 입력가능
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class Reservation(models.Model):
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # 예약한 사용자
    accommodation = models.ForeignKey(Accommodation, on_delete=models.CASCADE)
    check_in_date = models.DateField() # 체크인 날짜
    check_out_date = models.DateField() # 체크아웃 날짜
    status = models.BooleanField() # 예약 유무
    price = models.IntegerField(default=0) # 객실 가격
    create_at = models.DateField(auto_now_add=True) # 예약 날짜
    updated_at = models.DateField(auto_now=True) # 갱신 날짜



