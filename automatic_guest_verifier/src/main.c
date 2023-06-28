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

#include "hts.h"


#define BT_UUID_SERVICE BT_UUID_DECLARE_16(0x0001)
#define BT_UUID_CHARACTERISTIC BT_UUID_DECLARE_16(0x0002)

static uint8_t gatt_data[256] = {0};  // Datenpuffer für das Charakteristikum

static ssize_t spp_gatt_write(struct bt_conn *conn, const struct bt_gatt_attr *attr, const void *buf, uint16_t len, uint16_t offset, uint8_t flags)
{
    // Daten vom Flutter-App erhalten
    // Verarbeite die empfangenen Daten nach Bedarf
    // Du kannst auf die empfangenen Daten über den 'buf'-Zeiger zugreifen
    printk("Daten erhalten");
    // Sende eine Antwort zurück an das Flutter-App
    const char response[] = "Antwortdaten";
    memcpy(gatt_data, response, sizeof(response));
    return len;
}

static struct bt_gatt_attr spp_gatt_attrs[] = {
    BT_GATT_PRIMARY_SERVICE(BT_UUID_SERVICE),
    BT_GATT_CHARACTERISTIC(BT_UUID_CHARACTERISTIC, BT_GATT_CHRC_WRITE | BT_GATT_CHRC_WRITE_WITHOUT_RESP, BT_GATT_PERM_WRITE, NULL, spp_gatt_write, NULL),
};

static struct bt_gatt_service spp_gatt_service = BT_GATT_SERVICE(spp_gatt_attrs);

void setup_gatt_service(void)
{
    int err;

    err = bt_gatt_service_register(&spp_gatt_service);
    if (err) {
        printk("Failed to register GATT service (err %d)\n", err);
        return;
    }
}

static const struct bt_data ad[] = {
	BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
	BT_DATA_BYTES(BT_DATA_UUID16_ALL,
		      BT_UUID_16_ENCODE(BT_UUID_HTS_VAL),
		      BT_UUID_16_ENCODE(BT_UUID_DIS_VAL),
		      BT_UUID_16_ENCODE(BT_UUID_BAS_VAL)),
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

	hts_init();

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

static void bas_notify(void)
{
	uint8_t battery_level = bt_bas_get_battery_level();

	battery_level--;

	if (!battery_level) {
		battery_level = 100U;
	}

	bt_bas_set_battery_level(battery_level);
}

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
		k_sleep(K_SECONDS(1));

		/* Temperature measurements simulation */
		hts_indicate();

		/* Battery level simulation */
		bas_notify();
	}
	

}