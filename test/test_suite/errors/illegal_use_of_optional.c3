fn void syntaxErrors()
{
    int? i = 0;
    while (i + 1) {} // #error: optional, but was 'int?'
    if (i + 1) {} // #error: optional, but was 'int?'
    for (int x = i;;) {} // #error: 'int?' to 'int'
    for (int x = 0; x < i + 1;) {} // #error: optional, but was 'bool?'.
    for (int x = 0; x < 10; x += i + 1) {} // #error: Cannot assign an optional value to a non-optional
    switch (i + 1) // #error: optional, but was 'int?'
    {
        default:
            i + 1;
    }
}
