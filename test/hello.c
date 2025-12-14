// 裸函数 + 立即数方式直接输出“Hello World\n”到0x10000000
__attribute__((naked)) int main(void) {
    asm volatile( // C/C++ 中的一个编译器指令（GCC 等编译器支持），用来嵌入汇编代码并控制编译器的优化行为。
        ".option nopic\n"
        "lui  t1, 0x10000\n"
        "li   t2, 'H'\n"   // t2 = 0x00000048 = 72 = 'H'
        "sw   t2, 0(t1)\n" //将t2的值写入内存地址0x10000000
        "li   t2, 'e'\n"  // t2 = 0x00000065 = 101 = 'e'
        "sw   t2, 0(t1)\n" //将t2的值写入内存地址0x10000000
        "li   t2, 'l'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, 'l'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, 'o'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, ' '\n"
        "sw   t2, 0(t1)\n"
        "li   t2, 'W'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, 'o'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, 'r'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, 'l'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, 'd'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, '\\n'\n"
        "sw   t2, 0(t1)\n"
        "done:\n"
        "jal  x0, done\n"
    );
}

// ========== 之前的版本（已注释） ==========
// // 简单的Hello World程序
// // 这个程序会被编译成RISC-V机器码
//
// int main() {
//     // 简单的字符串输出（通过内存映射I/O或系统调用模拟）
//     // 为了简化，我们使用一个简单的循环和内存操作
//     
//     volatile int *output = (volatile int *)0x10000000;  // 假设的输出地址
//     char *str = "Hello World";
//     int i = 0;
//     
//     // 输出字符串
//     while (str[i] != '\0') {
//         *output = str[i];
//         i = i + 1;
//     }
//     
//     return 0;
// }

