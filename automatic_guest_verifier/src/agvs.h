#ifndef BT_AGVS_H
#define BT_AGVS_H

#include <bluetooth/gatt.h>

extern struct bt_gatt_service spp_gatt_service;
extern struct bt_gatt_service spp_gatt_service_admin;
extern struct bt_gatt_service spp_gatt_service_manage_admin;

void setup_gatt_service(void);

#define BT_UUID_SERVICE_ACCESS BT_UUID_DECLARE_16(0x0001)
#define BT_UUID_CHARACTERISTIC_ACCESS BT_UUID_DECLARE_16(0x0002)

#define BT_UUID_SERVICE_ADMIN BT_UUID_DECLARE_16(0x0003)
#define BT_UUID_CHARACTERISTIC_ADMIN BT_UUID_DECLARE_16(0x0004)

#define BT_UUID_SERVICE_MANAGE_ADMIN BT_UUID_DECLARE_16(0x0005)
#define BT_UUID_CHARACTERISTIC_MANAGE_ADMIN BT_UUID_DECLARE_16(0x0006)

#define BT_UUID_DESCRIPTOR BT_UUID_DECLARE_16(0x2902)

#endif /* BT_AGVS_H */
