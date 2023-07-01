/* main.c - Application main entry point */

/*
 * Copyright (c) 2019 Aaron Tsui <aaron.tsui@outlook.com>
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/types.h>
#include <stddef.h>
#include <string.h>
#include <errno.h>
#include <sys/printk.h>
#include <sys/byteorder.h>
#include <zephyr.h>

#include <device.h>

#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/conn.h>
#include <bluetooth/uuid.h>
#include <bluetooth/gatt.h>
#include <bluetooth/services/bas.h>
#include <bluetooth/rfcomm.h>


#define BT_UUID_SERVICE BT_UUID_DECLARE_16(0x0001)
#define BT_UUID_CHARACTERISTIC BT_UUID_DECLARE_16(0x0002)
#define BT_UUID_SERVICE_ADMIN BT_UUID_DECLARE_16(0x0003)
#define BT_UUID_CHARACTERISTIC_ADMIN BT_UUID_DECLARE_16(0x0004)
#define BT_UUID_DESCRIPTOR BT_UUID_DECLARE_16(0x2902)
#define BT_UUID_DESCRIPTOR_ADMIN BT_UUID_DECLARE_16(0x2903)

#define MAX_STRINGS 5
#define MAX_LENGTH 100

char strings[MAX_STRINGS][MAX_LENGTH];
int index = 0;

static bool isStringInArray(const char* searchString, const char stringArray[][MAX_LENGTH], int arraySize) {
    for (int i = 0; i < arraySize; i++) {
        if (strcmp(searchString, stringArray[i]) == 0) {
            return true; // String found in the array
        }
    }
    return false; // String not found in the array
}

static void writeID(const char* str){
	strcpy(strings[index], str);
	index ++;
}

static uint8_t gatt_data[20] = {0};  // Datenpuffer für das Charakteristikum

static ssize_t spp_gatt_write(struct bt_conn *conn, const struct bt_gatt_attr *attr, const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    // Daten vom Flutter-App erhalten
    // Verarbeite die empfangenen Daten nach Bedarf
    // Du kannst auf die empfangenen Daten über den 'buf'-Zeiger zugreifen
	writeID("b242071667515fc6");
	const char* str= (const char*)buf;
    printk("Daten erhalten %s", str);
 	char response[10];
	if(isStringInArray(str, strings, MAX_STRINGS)){
		// Sende eine Antwort zurück an das Flutter-App
		strcpy(response, "Komm rein");
	}else{
		strcpy(response, "Geh Weg!");
	}
    memcpy(gatt_data, response, sizeof(response));
	int success = bt_gatt_notify(conn, attr, gatt_data, sizeof(gatt_data));
	printk("Gesendet %d", success);

	return len; 
}

static ssize_t spp_gatt_write_admin(struct bt_conn *conn, const struct bt_gatt_attr *attr, const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    // Daten vom Flutter-App erhalten
    // Verarbeite die empfangenen Daten nach Bedarf
    // Du kannst auf die empfangenen Daten über den 'buf'-Zeiger zugreifen
	
	const char* str= (const char*)buf;
    printk("Daten erhalten %s", str);
	writeID(str);
 	char response[20] = "registered ";
	strcat(response, str);
    memcpy(gatt_data, response, sizeof(response));
	int success = bt_gatt_notify(conn, attr, gatt_data, sizeof(gatt_data));
	printk("Gesendet %d", success);

	return len; 
}

static struct bt_gatt_attr spp_gatt_attrs[] = {
    BT_GATT_PRIMARY_SERVICE(BT_UUID_SERVICE),
    BT_GATT_CHARACTERISTIC(BT_UUID_CHARACTERISTIC, BT_GATT_CHRC_WRITE | BT_GATT_CHRC_NOTIFY, BT_GATT_PERM_WRITE, NULL, spp_gatt_write, NULL),
	BT_GATT_DESCRIPTOR(BT_UUID_DESCRIPTOR, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE, NULL, NULL, NULL)
};

static struct bt_gatt_attr spp_gatt_attrs_admin[] = {
    BT_GATT_PRIMARY_SERVICE(BT_UUID_SERVICE_ADMIN),
    BT_GATT_CHARACTERISTIC(BT_UUID_CHARACTERISTIC_ADMIN, BT_GATT_CHRC_WRITE | BT_GATT_CHRC_NOTIFY, BT_GATT_PERM_WRITE_AUTHEN, NULL, spp_gatt_write_admin, NULL),
	BT_GATT_DESCRIPTOR(BT_UUID_DESCRIPTOR, BT_GATT_PERM_READ | BT_GATT_PERM_WRITE, NULL, NULL, NULL)
};

static struct bt_gatt_service spp_gatt_service = BT_GATT_SERVICE(spp_gatt_attrs);
static struct bt_gatt_service spp_gatt_service_admin = BT_GATT_SERVICE(spp_gatt_attrs_admin);

void setup_gatt_service(void)
{
    int err;

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
}




static const struct bt_data ad[] = {
	BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
	BT_DATA_BYTES(BT_DATA_UUID16_ALL,
	          BT_UUID_16_ENCODE(0x0002),
			  BT_UUID_16_ENCODE(0x0003)),
};


static void connected(struct bt_conn *conn, uint8_t err)
{
	if (err) {
		printk("Connection failed (err 0x%02x)\n", err);
	} else {
		printk("Connected\n");
	}
}

static void disconnected(struct bt_conn *conn, uint8_t reason)
{
	printk("Disconnected (reason 0x%02x)\n", reason);
}

BT_CONN_CB_DEFINE(conn_callbacks) = {
	.connected = connected,
	.disconnected = disconnected,
};

static void bt_ready(void)
{
	int err;

	printk("Bluetooth initialized\n");

	err = bt_le_adv_start(BT_LE_ADV_CONN_NAME, ad, ARRAY_SIZE(ad), NULL, 0);
	if (err) {
		printk("Advertising failed to start (err %d)\n", err);
		return;
	}

	printk("Advertising successfully started\n");
}

static void auth_cancel(struct bt_conn *conn)
{
	char addr[BT_ADDR_LE_STR_LEN];

	bt_addr_le_to_str(bt_conn_get_dst(conn), addr, sizeof(addr));

	printk("Pairing cancelled: %s\n", addr);
}

static struct bt_conn_auth_cb auth_cb_display = {
	.cancel = auth_cancel,
};

void main(void)
{
	int err;

	err = bt_enable(NULL);
	if (err) {
		printk("Bluetooth init failed (err %d)\n", err);
		return;
	}
	setup_gatt_service();

	bt_ready();

	
    bt_conn_auth_cb_register(&auth_cb_display);

	while (1) {

	}
	

}