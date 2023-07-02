#include "agvs.h"
#include "LinkedList.h"

#define MAX_STRINGS 15
#define MAX_LENGTH 100

#define PASSWORD "password"

static LinkedList list;

char extractFirstChar(char* str) {
    // Check if the string is empty or only contains whitespace
    if (str == NULL || *str == '\0' || *str == ' ') {
        return '\0';
    }

    // Extract the first character
    char firstChar = *str;

    // Remove the first character from the original string
    memmove(str, str + 1, strlen(str) + 1);

    return firstChar;
}

static uint8_t gatt_data[20] = {0};  // Datenpuffer für das Charakteristikum

static ssize_t request_access(struct bt_conn *conn, const struct bt_gatt_attr *attr, const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    // Daten vom Flutter-App erhalten
    // Verarbeite die empfangenen Daten nach Bedarf
    // Du kannst auf die empfangenen Daten über den 'buf'-Zeiger zugreifen
	const char* bufPtr = (const char*)buf;
    const int maxStrLen = 100;  // Maximum length of the string

    char str[maxStrLen + 1];  // Add 1 for the null-terminator
    strncpy(str, bufPtr, len);  // Copy 'len' characters from 'bufPtr' to 'str'
    str[len] = '\0';  // Null-terminate the copied string

    printk("Daten erhalten: %s", str);
 	char response[11];
	if(findListElement(&list, str)){
		// Sende eine Antwort zurück an das Flutter-App
		strcpy(response, "Komm rein!");
	}else{
		strcpy(response, "Geh Weg!!!");
	}
    memcpy(gatt_data, response, sizeof(response));
	int success = bt_gatt_notify(conn, attr, gatt_data, sizeof(gatt_data));
	printk("Gesendet %d", success);

	return len; 
}

static ssize_t authenticate_as_admin(struct bt_conn *conn, const struct bt_gatt_attr *attr, const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    const char* bufPtr = (const char*)buf;
    const int maxStrLen = 100;  // Maximum length of the string

    char str[maxStrLen + 1];  // Add 1 for the null-terminator
    strncpy(str, bufPtr, len);  // Copy 'len' characters from 'bufPtr' to 'str'
    str[len] = '\0';  // Null-terminate the copied string

    printk("Daten erhalten: %s", str);
	int response = 0;

 	if(!strcmp(str, PASSWORD)){
		response = 1;
	}else{
		response = 0;
	}
    memcpy(gatt_data, &response, sizeof(response));
	int success = bt_gatt_notify(conn, attr, gatt_data, sizeof(gatt_data));
	printk("Gesendet %d", success);

	return len; 
}

static ssize_t manage_user(struct bt_conn *conn, const struct bt_gatt_attr *attr, const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    const char* bufPtr = (const char*)buf;
    const int maxStrLen = 100;  // Maximum length of the string

    char str[maxStrLen + 1];  // Add 1 for the null-terminator
    strncpy(str, bufPtr, len);  // Copy 'len' characters from 'bufPtr' to 'str'
    str[len] = '\0';  // Null-terminate the copied string

	const char indicator = extractFirstChar(str);

    printk("Daten erhalten: %s", str);
	int response = 0;

 	if(!strcmp(&indicator, "a")){
		insert(&list, str);
		response = 1;
	}else if(!strcmp(&indicator, "d")){
		removeElement(&list, str);
		response = 1;
	}else{
		response = 0;
	}
    memcpy(gatt_data, &response, sizeof(response));
	int success = bt_gatt_notify(conn, attr, gatt_data, sizeof(gatt_data));
	printk("Gesendet %d", success);

	return len; 
}

static struct bt_gatt_attr spp_gatt_attrs[] = {
    BT_GATT_PRIMARY_SERVICE(BT_UUID_SERVICE_ACCESS),
    BT_GATT_CHARACTERISTIC(BT_UUID_CHARACTERISTIC_ACCESS, BT_GATT_CHRC_WRITE | BT_GATT_CHRC_NOTIFY, BT_GATT_PERM_WRITE, NULL, request_access, NULL),
	BT_GATT_DESCRIPTOR(BT_UUID_DESCRIPTOR, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE, NULL, NULL, NULL)
};

static struct bt_gatt_attr spp_gatt_attrs_admin[] = {
    BT_GATT_PRIMARY_SERVICE(BT_UUID_SERVICE_ADMIN),
    BT_GATT_CHARACTERISTIC(BT_UUID_CHARACTERISTIC_ADMIN, BT_GATT_CHRC_WRITE | BT_GATT_CHRC_NOTIFY, BT_GATT_PERM_WRITE, NULL, authenticate_as_admin, NULL),
	BT_GATT_DESCRIPTOR(BT_UUID_DESCRIPTOR, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE, NULL, NULL, NULL)
};

static struct bt_gatt_attr spp_gatt_attrs_manage_admin[] = {
    BT_GATT_PRIMARY_SERVICE(BT_UUID_SERVICE_MANAGE_ADMIN),
    BT_GATT_CHARACTERISTIC(BT_UUID_CHARACTERISTIC_MANAGE_ADMIN, BT_GATT_CHRC_WRITE | BT_GATT_CHRC_NOTIFY, BT_GATT_PERM_WRITE, NULL, manage_user, NULL),
	BT_GATT_DESCRIPTOR(BT_UUID_DESCRIPTOR, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE, NULL, NULL, NULL)
};

struct bt_gatt_service spp_gatt_service = BT_GATT_SERVICE(spp_gatt_attrs);
struct bt_gatt_service spp_gatt_service_admin = BT_GATT_SERVICE(spp_gatt_attrs_admin);
struct bt_gatt_service spp_gatt_service_manage_admin = BT_GATT_SERVICE(spp_gatt_attrs_manage_admin);

void setup_gatt_service(void)
{
    int err;
    initializeLinkedList(&list);
    err = bt_gatt_service_register(&spp_gatt_service);
    if (err) {
        printk("Failed to register GATT service (err %d)\n", err);
        return;
    }
	err = bt_gatt_service_register(&spp_gatt_service_admin);
	 if (err) {
        printk("Failed to register GATT service (err %d)\n", err);
        return;
    }
	err = bt_gatt_service_register(&spp_gatt_service_manage_admin);
	 if (err) {
        printk("Failed to register GATT service (err %d)\n", err);
        return;
    }
}