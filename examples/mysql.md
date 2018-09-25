#mysql操作

##进入mysql
``` 
kubectl exec -it mysql-pods-name bash

```

##mysql 修改密码
``` 
update user set authentication_string=password('12345678') where user="root";

flush privileges ;

```