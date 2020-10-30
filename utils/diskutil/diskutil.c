#include <stdio.h>
#include <string.h>

typedef unsigned int uint;
typedef unsigned char ubyte;

void read_sector(char * buf, unsigned long sector);
void init_disk();

char temp[512];
char filename[9];
char ext[4];

struct DiskInfo_T
{
    uint fat_region;
    uint root_region;
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

int main()
{
    init_disk();
    puts("Disk Utility for Z80\n\rBy Jay Valentine\n\r\n\r");
    read_sector(temp, 0);

    /* Calculate start of FAT. */
    disk_info.fat_region = get_uint(temp, 0x0e);

    uint sectors_per_fat = get_uint(temp, 0x16);
    uint number_of_fats = temp[0x10];

    disk_info.root_region = disk_info.fat_region + (sectors_per_fat * number_of_fats);

    /* Read the root directory. */
    read_sector(temp, disk_info.root_region);

    for (uint f = 0; f < 512; f += 32)
    {
        ubyte attr = temp[f+11];

        /* Skip if not actually a file. */
        if (attr & 0b00011010) continue;

        /* We're done if the first byte of the filename
         * is 0 */
        if (temp[f] == 0) break;

        memcpy(filename, &temp[f], 8);
        memcpy(ext, &temp[f+8], 3);

        /* Don't forget the null-terminator! */
        filename[8] = NULL;
        ext[3] = NULL;

        puts(filename);
        puts(".");
        puts(ext);
        puts("\n\r");
    }
}
