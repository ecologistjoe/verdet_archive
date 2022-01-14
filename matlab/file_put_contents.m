function file_put_contents(filename, contents, flags)

    if nargin < 3
        flags = 'w+';
    end

    f = fopen(filename, flags);
    fprintf(f, '%s', contents);
    fclose(f);