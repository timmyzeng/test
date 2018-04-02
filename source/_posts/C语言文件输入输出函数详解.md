---
title: C语言输入输出函数详解
date: 2018-03-15 19:56:44
tags:
categories:
    - "knowledge"
    - "C/C++"
keywords:
    - "C"
    - "文件操作"
    - "详解"
password:
---
### 总览
```c
//错误报告函数：
void perror( char const* str );
//终止执行函数：
void exit (int status);
//打开和关闭文件函数
FILE * fopen ( const char * filename, const char * mode );
int fclose ( FILE * stream );
//字符输入函数
int fgetc ( FILE * stream );
int getc ( FILE * stream );
int getchar ( void );
//字符输出函数
int fputc ( int character, FILE * stream );
int putc ( int character, FILE * stream );
int putchar ( int character );
//撤销字符函数：
int ungetc ( int character, FILE * stream );
//文本行输入函数
char * fgets ( char * str, int num, FILE * stream );
char* gets( char* str );
//文本行输出函数
int fputs ( const char * str, FILE * stream );
int puts ( const char * str );
//格式化输入函数
int fscanf( FILE* stream, const char* format, ... );
int scanf( const char* format, ... );
int sscanf( const char* s, const char* format, ... );
//格式化输出函数
int fprintf( FILE* stream, const char* format, ... );
int printf( const char* format, ... );
int sprintf( char* str, const char* format, ... );
//二进制I/O函数
size_t fread( void* ptr, size_t size, size_t count, FILE* stream );
size_t fwrite( void* ptr, size_t size, size_t count, FILE* stream );
//刷新缓冲区函数：
int fflush ( FILE * stream );
//文件流定位函数
long int ftell( FILE* stream );
int fseek( FILE* stream, long offset, int from );
//流错误函数
int feof( FILE* stream );
int ferror( FILE* stream );
void clearerr( FILE* stream );
```
<!--more-->
### 错误报告函数：void perror( char const* str );
先解释一个整型变量errno，这个变量是错误码，当一个库函数失败的时候，errno会被设置。
**形参**：str是一个字符串
**补充**：当一个程序执行了错误的操作的时候，操作系统设置一个errno，perror函数首先会将str中的信息打印出来，后面跟上一个分号和空格，在打印出一条用于解释errno当前错误码的信息。
**例子**：
```c
/* perror example */
#include <stdio.h>

int main ()
{
  FILE * pFile;
  pFile=fopen ("unexist.ent","rb");
  if (pFile==NULL)
    perror ("The following error occurred");
  else
    fclose (pFile);
  return 0;
}
```
如果文件unexist.ent不存在，那么将会输出以下信息：
![perror](http://p3ax8ersb.bkt.clouddn.com/201803152133_220.png-480.jpg)

**注意**：只有当一个库函数失败的时候，errno才会被设定。当函数成功运行的时候，errno并不会被设定。所以我们不能通过测试errno的值来判断是否有错误发生。

### 终止执行函数：void exit( int status );
**头文件**：stdlib.h
**形参**：status参数返还给操作系统。预定符号是EXIT_SUCCESS和EXIT_FAILURE。通常用0和EXIT_SUCCESS表示程序正常退出，用除零以外的整数和EXIT_FAILURE表示程序退出异常。
**补充**：我们经常将这个函数和perror配合起来使用，当我们发现了程序的错误的时候，用来终止程序的执行。
**例子**：
```c
/* exit example */
#include <stdio.h>      /* printf, fopen */
#include <stdlib.h>     /* exit, EXIT_FAILURE */

int main ()
{
  FILE * pFile;
  pFile = fopen ("myfile.txt","r");
  if (pFile==NULL)
  {
    printf ("Error opening file");
    exit (EXIT_FAILURE);
  }
  else
  {
    /* file operations here */
  }
  return 0;
}
```
如果文件myfile.txt不存在
![exit](http://p3ax8ersb.bkt.clouddn.com/201803152130_637.png-480.jpg)

### 打开文件函数：FILE\* fopen( char const\* filename, const char\* mode );
**形参**：两个参数都是字符串，filename是希望打开的文件或者设备名字；mode是用来表示流是用于只读、只写、读和写，以及是文本流还是二进制流。
**返回值**：如果成功打开文件，返回一个指向FILE类型的指针。失败返回一个NULL，并把错误码存入errno中。
**补充**：以一定的模式打开文件或设备。模式常见如下：
以下模式用文本流打开：

|模式|功能|
|:-:|-|
|"r"|read，只能读取，不能写入，同时要求文件必须存在。|
|"w"|write，只能写入，不能读取。若文件存在，那么清空文件内容再写入；若文件不存在，创建文件再写入。|
|"a"|append，只能写入，不能读取。若文件存在，在文件末尾添加内容；如果文件不存在，创建文件再写入。|
|"r+"|read/update，可读可写，要求文件必须存在。|
|"w+"|write/update，可读可写，如果文件存在，清空文件内容再写入；如果文件不存在，创建文件再写入。|
|"a+"|append/update，可读可写，若文件存在，在文件末尾添加内容；若文件不存在，创建文件再写入。|

以下模式用二进制流打开：
"rb", "wb", "ab", "r+b", "w+b", "a+b"或者"rb+", "wb+", "ab+"。功能和文本流一样，只是打开写入方式是二进制流。

二进制流和文本流的区别：
**文本流(text)**：指的是在流中流动的数据是 **以字符形式出现**的。举个例子：输入的时候，'\n'这个符号会被替换为回车CR和换行的ASCII码0DH和0AH。输出的时候，0DH和0AH被替换为'\n'。
**二进制流(binary)**：指的是在流中流动的数据是以 **二进制数字序列**出现的。**说白了就是在内存中是怎么存储的，输入到文件中也是怎么样存储的。**而且不会对'\n'进行替换。
举个例子：对于2001这个数
文本流用ASCII码表示：'2''0''0''1'分别是：50,48,48,49一共是四个字节
二进制流表示为：0000 0111 1101 0001转换为十六进制就是07D1，占用了两个字节。
此例来源：http://blog.csdn.net/barryCG/article/details/7621097

**例子**：
```c
/* fopen example */
#include <stdio.h>
int main ()
{
  FILE * pFile;
  pFile = fopen ("myfile.txt","w");
  if (pFile!=NULL)
  {
    fputs ("fopen example",pFile);
    fclose (pFile);
  }
  return 0;
}
```
如果没有myfile.txt这个文件，将会创建一个myfile.txt文件，并写入内容fopen example。
![fopen](http://p3ax8ersb.bkt.clouddn.com/201803161411_68.png-480.jpg)

### 关闭文件函数：int fclose( FILE* stream );
**形参**：stram是一个FILE类型指针指向的流文件。
**返回值**：当文件被正常关闭，返回一个整型的0；如果关闭异常，返回文件结束符EOF，通常被解释为整型的-1。
**补充**：我们习惯于将fopen和fclose搭配使用。fclose会在文件关闭的之前刷新缓冲区，将缓冲区的数据存入文件中，否则会有数据丢失。必要的时候，我们需要检测fclose的返回值是否正确，以避免数据丢失或。

### 输入输出函数总览

|家族名|目的|**可用于所有的流**|**只用于stdin或stdout**|内存中的字符串|
|:-:|:-:|:-:|:-:|:-:|
|getchar|字符输入|fget,getc|getchar|①|
|putchar|字符输出|fputc,putc|putchar|①|
|gets|文本行输入|fgets|gets|②|
|puts|文本行输出|fputs|puts|②|
|scanf|格式化输入|fscanf|scanf|sscanf|
|printf|格式化输出|fprintf|printf|sprintf|

①表示对指针使用下标引用或间接访问操作从内存中获得\写入一个字符
②使用strcpy函数从内存读取\写入文本行

### 字符输入函数：fgetc、getc、getchar
**函数原型：**
**int fgetc( FILE* stream ); 用于所有流**
**宏原型：**
**int getc(FILE* stream ); 用于所有流**
**int getchar( void ); 只能用于stdin**
**形参**：stram是一个FILE类型指针指向的流文件。
**返回值**：若读取成功，返回读取的一个字符，并实现整型提升。若到了文件的结束，返回EOF表示文本的结束。若读取失败，同样返回EOF并设置error变量。
**补充**：
1、函数作用是读取一个字符，同时文件指针向后指向下一个字符。
2、**返回值是整型，这是因为允许函数报告文件末尾(EOF)。**如果返回值是char型，那么256个字符中肯定有一个被指用于表示EOF。如果这个字符在文件内部出现，这个字符以后的内容不会被读取。因为这个字符被解释为EOF。**所以应该使用整型变量来接收这个字符**
3、fgetc是函数，getc和getchar是通过#define定义的宏。所以getc和getchar不能传入带有副作用的参数。同时，getc和getchar的效率会比fgetc快上一点。
4、getchar始终从标准输入读取一个字符。
**例子**：
```c
/* fgetc example: money counter */
#include <stdio.h>
#include <stdlib.h> //EXIT_FAILURE
int main ()
{
  FILE * pFile;
  int c;
  int n = 0;
  pFile=fopen ("myfile.txt","r");
  if (pFile==NULL)
  {
    perror ("Error opening file");
    exit(EXIT_FAILURE);
  }
  else
  {
    do {
      c = fgetc (pFile);
      if (c == '$') n++;
    } while (c != EOF);
    fclose (pFile);
    printf ("The file contains %d dollar sign characters ($).\n",n);
  }
  return 0;
}
```
上面代码用来统计myfile.txt中$符号的个数，在文件中输入五个，最后得到结果正确。
![myfile.txt](http://p3ax8ersb.bkt.clouddn.com/201803161526_445.png-480.jpg)
![fgetc](http://p3ax8ersb.bkt.clouddn.com/201803161528_779.png-480.jpg)
如果没有这个文件，将会执行perror程序，报错
![fgetc](http://p3ax8ersb.bkt.clouddn.com/201803161530_498.png-480.jpg)

### 字符输出函数：fputc、putc、putchar
**函数原型：**
**int fputc( int character, FILE* stream ); 用于所有流**
**宏原型：**
**int putc( int character, FILE* stream ); 用于所有流**
**int putchar( int character ); 只能用于stdout**
**形参**：character是将要被输出的字符；stram是一个FILE类型指针指向的流文件。
**返回值**：若函数执行成功，返回被写入的字符；若失败，返回EOF。同时errno被设置。
**补充**：
1、参数character在输入的时候会被裁剪为无符号整型。
2、fputc是真正的函数，putc和putchar是#define定义的宏函数。
3、putchar始终将字符打印在标准输出流。
例子：
```c
/* fputc example: alphabet writer */
#include <stdio.h>

int main ()
{
  FILE * pFile;
  char c;

  pFile = fopen ("alphabet.txt","w");
  if (pFile!=NULL) {
    for (c = 'A' ; c <= 'Z' ; c++)
      fputc ( c , pFile );
    fclose (pFile);
  }
  return 0;
}
```
上述代码将大写字符A~Z写入文件alphabet.txt中。
![fputc](http://p3ax8ersb.bkt.clouddn.com/201803161607_197.png-480.jpg)

### 撤销字符函数 ：int ungetc( int character, FILE* stream );
这个函数的作用是将先前读取到的字符返回到原来的流中，这样它可以在以后被重新读入。
**形参**：character是要返回的字符，stram是一个FILE类型指针指向的流文件。
**返回值**：若成功，返回被返回流中的字符；若失败，EOF被返回。
**补充**：
1、“退回”的字符和流当前的位置有关，所以如果用fseek、fsetpos、rewind函数改变了流的位置，所有退回的字符将被丢弃。
2、把字符退回到流中和写入到流中是不一样的。也就是从文件中读取出来后的退回，并不会影响到物理存储上的内容。
**例子**：
```c
/* ungetc example */
#include <stdio.h>

int main ()
{
    FILE * pFile;
    int c;
    char buffer [256];

    pFile = fopen ("myfile.txt","rt");
    if (pFile==NULL) perror ("Error opening file");
    else while (!feof (pFile)) {
        c=getc (pFile);
        if (c == EOF) break;
        if (c == '#') ungetc ('@',pFile);
        else ungetc (c,pFile);
        if (fgets (buffer,255,pFile) != NULL)
            fputs (buffer,stdout);
        else break;
    }
    return 0;
}
```
上述代码，将文件myfile.txt中每行开头的'#'替换为'@'。如果打开失败，打印"Error opening file"。
![myfile.txt](http://p3ax8ersb.bkt.clouddn.com/201803171040_523.png-480.jpg)
![ungetc](http://p3ax8ersb.bkt.clouddn.com/201803171039_852.png-480.jpg)
### 文本行输入函数：fgets、gets
**函数原型：**
**char\* fgets( char\* str, int num, FILE\* stream );**
**char\* gets( char\* str ); //一般不使用，不安全。完全可以用fgets代替。**
**形参**：str是目标字符串，num是一个整型参数；用来表示读取的字符个数,它包括了'\0'在内；stream是获取字符的流。
**返回值**：如果读取失败，也就是在读取任何字符之前就到了文件的结束，缓冲区没有被修改，返回一个NULL指针；如果读取成功，返回str。
**补充**：
1、当fgets读取到一个换行符并存储到缓冲区之后，结束读取。
2、如果读取的字符数量达到num-1个，结束读取。但是这种情况并不会出现数据丢失，因为下次调用fgets将从流的下一个字符开始读取。
3、任何一种情况下，一个NUL字节将被添加到缓冲区所存储数据的末尾，让其成为一个字符串。
**例子**：
```c
/* fgets example */
#include <stdio.h>

int main()
{
   FILE * pFile;
   char mystring [100];

   pFile = fopen ("myfile.txt" , "r");
   if (pFile == NULL) perror ("Error opening file");
   else {
     if ( fgets (mystring , 100 , pFile) != NULL )
       puts (mystring);
     fclose (pFile);
   }
   return 0;
}
```
上述代码，获取文件myfile.txt中的第一行字符串最多获取99个字符。
![myfile.txt](http://p3ax8ersb.bkt.clouddn.com/201803171101_159.png-480.jpg)
![fgets](http://p3ax8ersb.bkt.clouddn.com/201803171100_574.png-480.jpg)
**注意**：
1、fgets无法将字符串读取到一个长度小于两个字符的缓冲区，因为其中一个字符需要为NUL字节保留。
2、gets和fgets的不同，在于gets读取一行输入是，它不在缓冲区中存储结尾的换行符。
3、同时，应该注意的是，我们并不使用gets，因为它没有缓冲区长度参数，如果一个长输入行读到一个短缓冲区，多出来的字符将被写入到缓冲区后面的内存位置，这样会破坏此内存中的数据。

### 文本行输出函数：fputs、puts
**函数原型：**
**int fputs( const char\* str, FILE\* stream );**
**int puts( const char* str );**
**形参**：str是一个字符型指针，用来指向一个字符串，用来获取输入。
**返回值**：如果函数调用失败，返回EOF；成功返回一个非负数的值。
**补充**：
1、**fputs函数输出行的时候，不会将字符串的'\0'输出。**
```c
#include <stdio.h>

int main ()
{
    FILE *pFile;

    pFile = fopen("file.txt", "a");
    fputs("this is c", pFile);
    fputs("this is cpp", pFile);
    fclose(pFile);
    return(0);
}
```
上述代码可以证明，fputs不输出字符串结尾'\0'。
![fputs](http://p3ax8ersb.bkt.clouddn.com/201803171136_113.png-480.jpg)
2、**puts函数会在读取的字符串后面自动加上一个结尾符号'\0'，并输出到stdin中。**

### 格式化输入函数：fscanf、scanf、sscanf
**函数原型：**
**int fscanf( FILE\* stream, const char\* format, ... );**
**int scanf( const char* format, ... );**
**int sscanf( const char\* s, const char\* format, ... );**
**形参**：stream是一个FILE指针指向的流；format字符串是相应的格式。省略号表示一个可变长度的指针列代表。sscanf中的s指的是一个字符串，用来读取字符。
**返回值**：当字符串到达末尾或读取的输入不再匹配字符串所指定的类型的时候，输入停止。同时，被转换的输入值的个数当成函数的返回值；如果在任何输入值被转换之前文件就已经到达了尾部，返回EOF。
**补充**：
1、输入源的区别：fscanf的输入源是stream；scanf的输入源是标准输入stdin；sscanf的输入源是字符串s。
2、**这些函数的正常运行依赖于格式代码。必须保证指针参数的类型必须是对应格式代码的正确类型。否则将会产生垃圾值。**
比如下面例子：
```c
#include <stdio.h>

int main ()
{
    float a;
    scanf("%d", &a);
    printf("%f", a);
    return 0;
}
```
上述代码中a的类型是float，但是输入的时候指针参数的类型是整型，而格式代码是&a，是float类型。输出的时候用的是float输出，最终得到了垃圾值。
![scanf wrong](http://p3ax8ersb.bkt.clouddn.com/201803171221_916.png-480.jpg)
3、为什么scanf中需要用&符号。这个是因为在c中是传值调用，如果需要修改当前值地址的内容就需要传递一个地址。否则将会程序崩溃。
4、format字符串参数解析：
(1)空白字符：它们与输入中的零个或多个空白字符匹配，在处理的过程中被忽略。
(2)格式代码：它们指定函数如何解释接下来的输入字符。
(3)其他字符：当任何其他字符出现在格式字符串时，下一个输入字符必须与之匹配。如果匹配，该字符被丢弃。如果不匹配，函数结束读取。
5、格式代码解析：上述代码都是以%开头，接下来接：
(1)星号：星号将转换后的值被丢弃而不是存储，可以用来跳过不需要输入的字符。
(2)宽度：以一个非负整数给出，它限制被读取用于转换的输入字符个数。如果没有给出宽度，那么就连续读入字符直到遇到输入中的下一个空白字符。
下面这个例子给出宽度的用法：
```c
#include <stdio.h>

int main(){
    int a = 0;
    int b = 0;
    int c = 0;
    FILE* input = fopen("input.txt", "r");
    if (input == NULL) perror ("Error opening file");
    else{
        fscanf(input, "%4d %4d %4d", &a, &b, &c);
        printf("a = %d\n", a);
        printf("b = %d\n", b);
        printf("c = %d\n", c);
    }
    return 0;
}
```
input.txt中存放如下：
![input](http://p3ax8ersb.bkt.clouddn.com/201803221654_415.png-480.jpg)
输出如下：只有a和b改变，c未改变。
![out](http://p3ax8ersb.bkt.clouddn.com/201803221656_996.png-480.jpg)
如果input.txt中存放如下；
![input2](http://p3ax8ersb.bkt.clouddn.com/201803221657_130.png-480.jpg)
输出如下：a=1234，b=5，c=6789。0被舍弃
![out2](http://p3ax8ersb.bkt.clouddn.com/201803221657_608.png-480.jpg)
**注意：在使用fscanf函数的时候，文件中的换行符也被当成了空白字符跳过。**
(3)限定符：h,l,L；限定符的目的是为了指定参数的长度。具体见下表：
![限定符](http://p3ax8ersb.bkt.clouddn.com/201803192128_815.png-1920.jpg)
(4)格式代码：就是单个字符，用于指定输入字符将被如何解析。上表中的第一列就是部分格式代码。具体见下表：
![格式代码](http://p3ax8ersb.bkt.clouddn.com/201803192131_223.png-1920.jpg)
例子：
```c
/* scanf example */
#include <stdio.h>

int main ()
{
  char str [80];
  int i;

  printf ("Enter your family name: ");
  scanf ("%79s",str);
  printf ("Enter your age: ");
  scanf ("%d",&i);
  printf ("Mr. %s , %d years old.\n",str,i);
  printf ("Enter a hexadecimal number: ");
  scanf ("%x",&i);
  printf ("You have entered %#x (%d).\n",i,i);

  return 0;
}
```
上述例子就是对各种格式的输入。
![scanf](http://p3ax8ersb.bkt.clouddn.com/201803221706_580.png-480.jpg)
### 格式化输出函数：fprintf、printf、sprintf
**函数原型：**
**int fprintf( FILE\* stream, const char\* format, ... );**
**int printf( const char* format, ... );**
**int sprintf( char\* str, const char\* format, ... );**
**形参**：stream是一个FILE指针指向的流；format字符串是相应的格式。省略号表示一个可变长度的指针列代表。sprintf中str是一个用来存储字符的指定字符串。
**返回值**：返回值就是实际打印或者存储的字符个数。
**补充**：
1、sprintf是一个容易出错的函数，因为缓冲区的大小并没有作为一个形参被传入。函数并不知道该输入多少个字符是安全的。
2、printf家族函数和scanf家族函数一样，必须保证值和格式码表示一致。
3、format字符串中含有格式代码，格式代码由一个百分号开头，后面可以跟：
(1)零个或者多个标志字符。
(2)一个可选的最小字段宽度
(3)一个可选的精度
(4)一个可选的修改符
(5)转换类型
4、格式代码如下：
![格式代码](http://p3ax8ersb.bkt.clouddn.com/201803221716_63.png-1920.jpg)
5、格式标志如下：
![格式标志](http://p3ax8ersb.bkt.clouddn.com/201803221717_596.png-1920.jpg)
### 二进制I/O函数：
**函数原型：**
**size_t fread( void\* ptr, size_t size, size_t count, FILE\* stream );**
**size_t fwrite( void\* ptr, size_t size, size_t count, FILE\* stream );**
**形参**：ptr是一个指向用于保存数据的内存位置的指针，至少有size*count个字节；size是缓冲区中每个元素的字节数；count是读取的元素数。
**返回值**：实际读取的元素(非字节)的数目，如果过程中遇到了文件尾，这个数字可能比请求的元素数目小。
**补充**：一般来说，二进制的写入效率比文件写入要高，因为二进制输出避免了在数值转换为字符串过程中所涉及的开销和精读损失。但是很遗憾的是，二进制的数据，不是我们人眼可以阅读的。文本写入的文件就可以很好的阅读。
**例子**：
```c
/* fread example: read an entire file */
#include <stdio.h>
#include <stdlib.h>

int main () {
  FILE * pFile;
  long lSize;
  char * buffer;
  size_t result;

  pFile = fopen ( "myfile.bin" , "rb" );
  if (pFile==NULL) {fputs ("File error",stderr); exit (1);}

  // obtain file size:
  fseek (pFile , 0 , SEEK_END);
  lSize = ftell (pFile);
  rewind (pFile);

  // allocate memory to contain the whole file:
  buffer = (char*) malloc (sizeof(char)*lSize);
  if (buffer == NULL) {fputs ("Memory error",stderr); exit (2);}

  // copy the file into the buffer:
  result = fread (buffer,1,lSize,pFile);
  if (result != lSize) {fputs ("Reading error",stderr); exit (3);}

  /* the whole file is now loaded in the memory buffer. */

  // terminate
  fclose (pFile);
  free (buffer);
  return 0;
}
```
上述例子将文件myfile.bin中的数据，通过函数fread读取到数组buffer中去。

### 刷新缓冲区函数：int fflush( FILE* stream );
**返回值**：若函数正确执行返回一个0，若失败，返回EOF同时error被设置。
**补充**：这个函数会立刻刷新缓冲区，如果我们需要输入的字符立刻写入的话，我们可以调动这个函数。
**例子**：
```c
/* fflush example */
#include <stdio.h>
char mybuffer[80];
int main()
{
   FILE * pFile;
   pFile = fopen ("example.txt","r+");
   if (pFile == NULL) perror ("Error opening file");
   else {
     fputs ("test",pFile);
     fflush (pFile);    // flushing or repositioning required
     fgets (mybuffer,80,pFile);
     puts (mybuffer);
     fclose (pFile);
     return 0;
  }
}
```
上述例子，使用了fflush将缓冲区中的test立刻刷新到文件流pFile中，然后从pFile中获取最多80个字符到mybuffer中。并打印到屏幕上。
example.txt存储内容如下：
![example.txt1](http://p3ax8ersb.bkt.clouddn.com/201803201500_50.png-480.jpg)
执行程序之后的输出：从被替换的第四个字符开始输出，这个是因为文本指针已经指向第四个字符。
![stdout1](http://p3ax8ersb.bkt.clouddn.com/201803201502_589.png-480.jpg)
执行之后的example.txt内容：前四个字符被替换成text
![example.txt2](http://p3ax8ersb.bkt.clouddn.com/201803201502_452.png-480.jpg)
如果没有刷新函数fflush将会出现下面情况：
输出如下：此时的缓冲区未刷新，内容并没有写入文本流pFile中。
![stdout2](http://p3ax8ersb.bkt.clouddn.com/201803201504_487.png-960.jpg)
example.txt3内容：当调用puts函数的时候，缓冲区的内容被刷新，所有缓冲区的内容被写入pFile中
![example.txt3](http://p3ax8ersb.bkt.clouddn.com/201803201505_936.png-960.jpg)
### 文件流定位函数：ftell、fseek
**函数原型：**
**long int ftell( FILE* stream );**
**int fseek( FILE* stream, long offset, int from );**
**形参**：参考下表：
![from](http://p3ax8ersb.bkt.clouddn.com/201803201520_375.png-1920.jpg)
**补充**：
1、**ftell返回流的当前位置**。这函数允许你保存一个文件的当前位置，可能在将来会返回到这个位置。在二进制流中，这个值就是当前位置距离文件起始位置之间的字节数。
2、**fseek允许你定位在流中的位置**，用于下次的读取或写入。
3、**在二进制流中，从SEEK_END进行定位可能不被支持，应该避免。在文本流中，如果from是SEEK_CUR或SEEK_END，offset必须是零。如果from是SEEK_SET，offset必须是一个从同一个流中以前调用ftell所返回的值。**
4、这些限制的存在，部分原因是因为文本流所执行的行末字符映射。由于这个映射的存在，文本文件的字节数可能和程序写入的字节数不同。
5、用fseek改变一个流的位置会带来三个副作用。第一个，行末指示字符会被清除；**第二个，在fseek之前用ungetc退还给流的字符，会被丢失；**第三个，定位允许你从写入切换到读取，或者回到打开的流用来更新。
**例子**：
```c
/* ftell example : getting size of a file */
#include <stdio.h>

int main ()
{
  FILE * pFile;
  long size;

  pFile = fopen ("myfile.txt","r");
  if (pFile==NULL) perror ("Error opening file");
  else
  {
    fseek (pFile, 0, SEEK_END);   // non-portable
    size=ftell (pFile);
    fclose (pFile);
    printf ("Size of myfile.txt: %ld bytes.\n",size);
  }
  return 0;
}
```
上述程序就是通过利用fseek函数将文件指针定位到文本末，然后通过ftell函数获取当前位置。这样可以统计出文件字节数。
![myfile.txt](http://p3ax8ersb.bkt.clouddn.com/201803201536_822.png-480.jpg)
![size](http://p3ax8ersb.bkt.clouddn.com/201803201536_82.png-480.jpg)
下面这个例子说明了文本文件下，换行符被编译为两个字符，分别是`'\n''\r'`
![myfile.txt2](http://p3ax8ersb.bkt.clouddn.com/201803201539_304.png-480.jpg)
![size2](http://p3ax8ersb.bkt.clouddn.com/201803201539_965.png-480.jpg)
### 流错误函数：feof、ferror、clearerr
**函数原型：**
**int feof( FILE* stream );**
**int ferror( FILE* stream );**
**void clearerr( FILE* stream );**
**返回值**：若到了文件的结束，返回一个非零的值；若不是文件结尾，返回一个零。
**补充**：
1、feof函数检查文件指针是否指向文本结束符。ferror函数报告流的错误状态。clearerr对指定流的错误标准进行重置。
2、函数clearerr、rewind、fseek会清除文末指示符，当时下次有I/O函数操作这个流，文末指示符会被重新设定。
**例子**：
```c
/* feof example: byte counter */
#include <stdio.h>

int main ()
{
  FILE * pFile;
  int n = 0;
  pFile = fopen ("myfile.txt","rb");
  if (pFile==NULL) perror ("Error opening file");
  else
  {
    while (fgetc(pFile) != EOF) {
      ++n;
    }
    if (feof(pFile)) {
      puts ("End-of-File reached.");
      printf ("Total number of bytes read: %d\n", n);
    }
    else puts ("End-of-File was not reached.");
    fclose (pFile);
  }
  return 0;
}
```
上述代码读取文件中的字符个数， 并在文件结束的时候，返回读取字符个数。
![myfile.txt](http://p3ax8ersb.bkt.clouddn.com/201803201611_34.png-480.jpg)
![feof](http://p3ax8ersb.bkt.clouddn.com/201803201610_320.png-480.jpg)

**本文中的知识点来自于C和指针，代码例子绝大部分来自网站www.cplusplus.com**