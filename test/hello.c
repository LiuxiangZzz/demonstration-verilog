// 裸函数 + 立即数方式直接输出“Hello World\n”到0x10000000
__attribute__((naked)) int main(void) {
    asm volatile(
        ".option nopic\n"
        "lui  t1, 0x10000\n"
        "li   t2, 'H'\n"
        "sw   t2, 0(t1)\n"
        "li   t2, 'e'\n"
        "sw   t2, 0(t1)\n"
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

