// 简单的Hello World程序
// 这个程序会被编译成RISC-V机器码

int main() {
    // 简单的字符串输出（通过内存映射I/O或系统调用模拟）
    // 为了简化，我们使用一个简单的循环和内存操作
    
    volatile int *output = (volatile int *)0x10000000;  // 假设的输出地址
    char *str = "Hello World";
    int i = 0;
    
    // 输出字符串
    while (str[i] != '\0') {
        *output = str[i];
        i = i + 1;
    }
    
    return 0;
}

