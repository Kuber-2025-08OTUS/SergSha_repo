import kopf
import kubernetes.client
from kubernetes.client.rest import ApiException
import yaml
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO)

@kopf.on.create('otus.homework', 'v1', 'mysqls')
def create_mysql_instance(spec, name, namespace, logger, **kwargs):
    """Создание всех ресурсов для MySQL инстанса"""
    
    # Параметры из CRD
    image = spec.get('image', 'mysql:8.0')
    database = spec.get('database', 'defaultdb')
    password = spec.get('password', '')
    storage_size = spec.get('storage_size', '10Gi')
    
    logger.info(f"Создание MySQL инстанса {name} в namespace {namespace}")
    logger.info(f"Параметры: image={image}, database={database}, storage={storage_size}")
    
    # Создание PersistentVolume
    pv_manifest = create_pv_manifest(name, storage_size)
    kopf.adopt(pv_manifest)
    
    # Создание PersistentVolumeClaim
    pvc_manifest = create_pvc_manifest(name, namespace, storage_size)
    kopf.adopt(pvc_manifest)
    
    # Создание Service
    service_manifest = create_service_manifest(name, namespace)
    kopf.adopt(service_manifest)
    
    # Создание Deployment
    deployment_manifest = create_deployment_manifest(
        name, namespace, image, database, password, storage_size
    )
    kopf.adopt(deployment_manifest)
    
    # Применение манифестов
    api = kubernetes.client.CoreV1Api()
    apps_api = kubernetes.client.AppsV1Api()
    
    try:
        # Создаем PersistentVolume
        api.create_persistent_volume(body=pv_manifest)
        logger.info(f"PersistentVolume {name} создан")
        
        # Создаем PersistentVolumeClaim
        api.create_namespaced_persistent_volume_claim(
            namespace=namespace, body=pvc_manifest
        )
        logger.info(f"PersistentVolumeClaim {name} создан")
        
        # Создаем Service
        api.create_namespaced_service(namespace=namespace, body=service_manifest)
        logger.info(f"Service {name} создан")
        
        # Создаем Deployment
        apps_api.create_namespaced_deployment(
            namespace=namespace, body=deployment_manifest
        )
        logger.info(f"Deployment {name} создан")
        
    except ApiException as e:
        logger.error(f"Ошибка при создании ресурсов: {e}")
        raise kopf.TemporaryError(f"Ошибка создания ресурсов: {e}", delay=30)

@kopf.on.delete('otus.homework', 'v1', 'mysqls')
def delete_mysql_instance(name, namespace, logger, **kwargs):
    """Удаление всех ресурсов при удалении MySQL инстанса"""
    
    logger.info(f"Удаление MySQL инстанса {name} из namespace {namespace}")
    
    api = kubernetes.client.CoreV1Api()
    apps_api = kubernetes.client.AppsV1Api()
    
    try:
        # Удаляем Deployment
        apps_api.delete_namespaced_deployment(
            name=f"mysql-{name}",
            namespace=namespace
        )
        logger.info(f"Deployment mysql-{name} удален")
        
        # Удаляем Service
        api.delete_namespaced_service(
            name=f"mysql-{name}",
            namespace=namespace
        )
        logger.info(f"Service mysql-{name} удален")
        
        # Удаляем PVC
        api.delete_namespaced_persistent_volume_claim(
            name=f"mysql-{name}-pvc",
            namespace=namespace
        )
        logger.info(f"PVC mysql-{name}-pvc удален")
        
        # Удаляем PV
        api.delete_persistent_volume(name=f"mysql-{name}-pv")
        logger.info(f"PV mysql-{name}-pv удален")
        
    except ApiException as e:
        if e.status != 404:  # Игнорируем ошибки "не найден"
            logger.error(f"Ошибка при удалении ресурсов: {e}")
            raise kopf.TemporaryError(f"Ошибка удаления ресурсов: {e}", delay=30)

@kopf.on.field('otus.homework', 'v1', 'mysqls', field='spec.image')
def update_mysql_image(spec, old, new, name, namespace, logger, **kwargs):
    """Обработка изменения образа MySQL"""
    if old != new:
        logger.info(f"Обновление образа MySQL для {name}: {old} -> {new}")
        update_deployment_image(name, namespace, new, logger)

def create_pv_manifest(name, storage_size):
    """Создание манифеста для PersistentVolume"""
    return {
        'apiVersion': 'v1',
        'kind': 'PersistentVolume',
        'metadata': {
            'name': f'mysql-{name}-pv',
            'labels': {
                'app': 'mysql',
                'instance': name,
                'created-by': 'mysql-operator'
            }
        },
        'spec': {
            'capacity': {'storage': storage_size},
            'accessModes': ['ReadWriteOnce'],
            'persistentVolumeReclaimPolicy': 'Retain',
            'storageClassName': 'manual',
            'hostPath': {
                'path': f'/data/mysql-{name}'
            }
        }
    }

def create_pvc_manifest(name, namespace, storage_size):
    """Создание манифеста для PersistentVolumeClaim"""
    return {
        'apiVersion': 'v1',
        'kind': 'PersistentVolumeClaim',
        'metadata': {
            'name': f'mysql-{name}-pvc',
            'namespace': namespace,
            'labels': {
                'app': 'mysql',
                'instance': name,
                'created-by': 'mysql-operator'
            }
        },
        'spec': {
            'storageClassName': 'manual',
            'accessModes': ['ReadWriteOnce'],
            'resources': {
                'requests': {'storage': storage_size}
            },
            'volumeName': f'mysql-{name}-pv'
        }
    }

def create_service_manifest(name, namespace):
    """Создание манифеста для Service"""
    return {
        'apiVersion': 'v1',
        'kind': 'Service',
        'metadata': {
            'name': f'mysql-{name}',
            'namespace': namespace,
            'labels': {
                'app': 'mysql',
                'instance': name,
                'created-by': 'mysql-operator'
            }
        },
        'spec': {
            'type': 'ClusterIP',
            'ports': [
                {
                    'port': 3306,
                    'targetPort': 3306,
                    'name': 'mysql'
                }
            ],
            'selector': {
                'app': 'mysql',
                'instance': name
            }
        }
    }

def create_deployment_manifest(name, namespace, image, database, password, storage_size):
    """Создание манифеста для Deployment"""
    return {
        'apiVersion': 'apps/v1',
        'kind': 'Deployment',
        'metadata': {
            'name': f'mysql-{name}',
            'namespace': namespace,
            'labels': {
                'app': 'mysql',
                'instance': name,
                'created-by': 'mysql-operator'
            }
        },
        'spec': {
            'replicas': 1,
            'selector': {
                'matchLabels': {
                    'app': 'mysql',
                    'instance': name
                }
            },
            'template': {
                'metadata': {
                    'labels': {
                        'app': 'mysql',
                        'instance': name
                    }
                },
                'spec': {
                    'containers': [
                        {
                            'name': 'mysql',
                            'image': image,
                            'ports': [
                                {
                                    'containerPort': 3306,
                                    'name': 'mysql'
                                }
                            ],
                            'env': [
                                {
                                    'name': 'MYSQL_ROOT_PASSWORD',
                                    'value': password
                                },
                                {
                                    'name': 'MYSQL_DATABASE',
                                    'value': database
                                }
                            ],
                            'volumeMounts': [
                                {
                                    'name': 'mysql-storage',
                                    'mountPath': '/var/lib/mysql'
                                }
                            ],
                            'resources': {
                                'requests': {
                                    'memory': '256Mi',
                                    'cpu': '100m'
                                },
                                'limits': {
                                    'memory': '512Mi',
                                    'cpu': '500m'
                                }
                            }
                        }
                    ],
                    'volumes': [
                        {
                            'name': 'mysql-storage',
                            'persistentVolumeClaim': {
                                'claimName': f'mysql-{name}-pvc'
                            }
                        }
                    ]
                }
            }
        }
    }

def update_deployment_image(name, namespace, new_image, logger):
    """Обновление образа в Deployment"""
    apps_api = kubernetes.client.AppsV1Api()
    
    try:
        deployment = apps_api.read_namespaced_deployment(
            name=f"mysql-{name}",
            namespace=namespace
        )
        
        deployment.spec.template.spec.containers[0].image = new_image
        
        apps_api.patch_namespaced_deployment(
            name=f"mysql-{name}",
            namespace=namespace,
            body=deployment
        )
        
        logger.info(f"Образ MySQL обновлен на {new_image}")
        
    except ApiException as e:
        logger.error(f"Ошибка при обновлении образа: {e}")
        raise kopf.TemporaryError(f"Ошибка обновления образа: {e}", delay=30)