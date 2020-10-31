#include <stdio.h>
#include <string.h>

extern void * nonboot;

typedef unsigned long ulong;
typedef unsigned int uint;
typedef unsigned char ubyte;

void read_sector(char * buf, unsigned long sector);
void write_sector(char * buf, unsigned long sector);
void init_disk();

char temp[512];
char input[256];
char * cmd;
char * argv[256];
size_t argc;

struct DiskInfo_T
{
    /* Region start sectors. */
    ulong fat_region;
    ulong root_region;
    ulong data_region;

    /* Other info. */
    ubyte sectors_per_cluster;
} disk_info;

/* Get an unsigned integer (in Z80 little-endian)
 * from a buffer at the given position.
 */
uint get_uint(char * buf, uint i)
{
    uint hi = buf[i+1];
    uint lo = buf[i];
    return (hi << 8) | lo;
}

ulong first_sector_of_cluster(uint n)
{
    return disk_info.data_region + ((n - 2) * disk_info.sectors_per_cluster);
}

int find_file(char * buf, const char * name)
{
    /* Holds filename+extension, maximum 12 characters. */
    char filename[13];
    for (uint i = 0; i < 13; i++)
    {
        filename[i] = 0;
    }

    /* Search just the first sector of the root directory
     * for now. */
    read_sector(temp, disk_info.root_region);

    for (uint f = 0; f < 512; f += 32)
    {
        ubyte attr = temp[f+11];

        /* Skip if not actually a file. */
        if (attr & 0b00011010) continue;

        /* If the first byte of the filename is 0
         * then there are no more files. */
        if (temp[f] == 0) break;

        /* Copy filename. */
        memcpy(filename, &temp[f], 8);

        /* Find first space in filename.
         * If filename is 8 bytes, there won't be one. */
        ubyte i;
        for (i = 0; i < 8; i++)
        {
            if (filename[i] == ' ') break;
        }

        /* i now points to the byte after the last character
         * in the filename. We can start constructing the ext. */
        filename[i] = '.';

        /* Copy extension. */
        memcpy(&filename[i+1], &temp[f+8], 3);

        /* Don't forget the null-terminator! */
        filename[i + 4] = NULL;
        
        /* Compare to search name.
         * If a match, copy directory entry into buffer and return. */
        if (strcmp(filename, name) == 0)
        {
            memcpy(buf, &temp[f], 32);
            return 0;
        }
    }

    return 1;
}

int main()
{
    char dir_entry[32];

    init_disk();
    puts("Disk Utility for Z80\n\r\n\r");
    read_sector(temp, 0);

    /* General disk info. */
    disk_info.sectors_per_cluster = temp[0x0d];

    /* Calculate start of FAT. */
    disk_info.fat_region = get_uint(temp, 0x0e);

    uint sectors_per_fat = get_uint(temp, 0x16);
    uint number_of_fats = temp[0x10];

    /* Calculate start of root directory. */
    disk_info.root_region = disk_info.fat_region + (sectors_per_fat * number_of_fats);

    uint root_directory_size = get_uint(temp, 0x11) / 16;

    /* Calculate start of data region. */
    disk_info.data_region = disk_info.root_region + root_directory_size;

    /* Interactive prompt. */
    while (1)
    {
        puts("> ");
        gets(input);
        argc = 0;

        /* We expect at least one token. */
        cmd = strtok(input, " ");

        if (cmd == NULL) continue;

        /* Process the rest of the tokens, if any. */
        while (1)
        {
            char * p = strtok(NULL, " ");
            if (p == NULL) break;

            argv[argc] = p;
            argc++;
        }

        if (strcmp(cmd, "type") == 0)
        {
            if (argc < 1)
            {
                puts("Expected at least one argument.\n\r");
            }
            else
            {
                char * filename = argv[0];

                if (find_file(temp, filename) == 0)
                {
                    uint cluster = get_uint(temp, 0x1a);
                    ulong sector = first_sector_of_cluster(cluster);
                    read_sector(temp, sector);
                    puts(temp);
                }
                else
                {
                    printf("Could not find file: %s\n\r", filename);
                }
            }
        }
        else if (strcmp(cmd, "makedisk") == 0)
        {
            /* First copy the executable code. We'll overlay everything else onto that. */
            memcpy(temp, nonboot, 512);

            /* Drive signature. */
            temp[510] = 0xAA;
            temp[511] = 0x55;

            /* Write bootable sector. */
            write_sector(temp, 0);
        }
    }
}
